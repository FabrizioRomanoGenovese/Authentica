// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;


import "forge-std/Test.sol";
import "./utils/mocks/MockAuthentica.sol";


contract AuthenticaTest is MockAuthentica, Test {
    MockAuthentica internal authentica;

    function setUp() public {
        authentica = new MockAuthentica();
    }

    function testOwnership() public {
        assertEq(address(this), authentica.owner());
    }

    /*///////////////////////////////////////////////////////////////
                              SECRET LOGIC
    //////////////////////////////////////////////////////////////*/

    function testSecretBasicSanity(
        bytes32 secret,
        address user
    ) public {
        vm.prank(user);
        uint256 resultId = authentica.checkId(secret);
        uint256 resultAllowance = authentica.checkAllowance(secret);
        bool resultLocked = authentica.checkLocked(secret);
        assertEq(resultId, 0);
        assertEq(resultAllowance, 0);
        assertEq(resultLocked, false);
    }

    function testPushSecretOwner(
        bytes32 secret,
        uint256 id,
        uint256 allowance
    ) public {
        authentica.pushSecret(secret, id, allowance);
        uint256 resultId = authentica.checkId(secret);
        uint256 resultAllowance = authentica.checkAllowance(secret);
        bool resultLocked = authentica.checkLocked(secret);
        assertEq(resultId, id);
        assertEq(resultAllowance, allowance);
        assertEq(resultLocked, false);
    }

    function testPushSecretUser(
        bytes32 secret,
        uint256 id,
        uint256 allowance,
        address user
    ) public {
        vm.expectRevert('Ownable: caller is not the owner');
        vm.assume(user != address(this));
        vm.prank(user);
        authentica.pushSecret(secret, id, allowance);
    }

    function testBatchPushSecretOwner(
        bytes32[] memory secrets,
        uint256[] memory ids,
        uint256[] memory allowances,
        uint64 l
    ) public {
        vm.assume(
            secrets.length > l &&
            ids.length > l &&
            allowances.length > l&& 
            l > 0
        );
        bytes32[] memory newSecrets = new bytes32[](l);
        uint256[] memory newIds = new uint256[](l);
        uint256[] memory newAllowances = new uint256[](l);
        for (uint64 i = 0; i < l; ) {
            newSecrets[i] = secrets[i];
            newIds[i] = ids[i];
            newAllowances[i] = allowances[i];
            for (uint64 j = 0; j < i; ) {
                // Writing to the same secret overwrites the rest, making it fail
                vm.assume(newSecrets[i] != newSecrets[j]);
                unchecked {
                    j++;
                }
            }
            unchecked {
                i++;
            }
        }
        authentica.batchPushSecret(newSecrets, newIds, newAllowances);
        for (uint64 k = 0; k < l; ) {
            uint256 resultId = authentica.checkId(newSecrets[k]);
            uint256 resultAllowance = authentica.checkAllowance(newSecrets[k]);
            bool resultLocked = authentica.checkLocked(newSecrets[k]);
            assertEq(resultId, newIds[k]);
            assertEq(resultAllowance, newAllowances[k]);
            assertEq(resultLocked, false);
            unchecked {
                k++;
            }
        }
    }

    function testBatchPushSecretUser(
        bytes32[] memory secrets,
        uint256[] memory ids,
        uint256[] memory allowances,
        uint64 l,
        address user
    ) public {
        vm.expectRevert('Ownable: caller is not the owner');
        vm.assume(user != address(this));
        vm.prank(user);
        vm.assume(
            secrets.length > l &&
            ids.length > l &&
            allowances.length > l&& 
            l > 0
        );
        bytes32[] memory newSecrets = new bytes32[](l);
        uint256[] memory newIds = new uint256[](l);
        uint256[] memory newAllowances = new uint256[](l);
        for (uint64 i = 0; i < l; ) {
            newSecrets[i] = secrets[i];
            newIds[i] = ids[i];
            newAllowances[i] = allowances[i];
            unchecked {
                i++;
            }
        }
        authentica.batchPushSecret(newSecrets, newIds, newAllowances);
    }

    function testLockSecretOwner(
        bytes32 secret
    ) public {
        authentica.lockSecret(secret);
        bool resultLocked = authentica.checkLocked(secret);
        assertEq(resultLocked, true);
    }

    function testLockSecretUser(
        bytes32 secret,
        address user
    ) public {
        vm.expectRevert('Ownable: caller is not the owner');
        vm.assume(user != address(this));
        vm.prank(user);
        authentica.lockSecret(secret);
    }

    function testBatchLockSecretOwner(
        bytes32[] memory secrets,
        uint256[] memory ids,
        uint256[] memory allowances,
        uint64 l
    ) public {
        vm.assume(
            secrets.length > l &&
            ids.length > l &&
            allowances.length > l&& 
            l > 0
        );
        bytes32[] memory newSecrets = new bytes32[](l);
        uint256[] memory newIds = new uint256[](l);
        uint256[] memory newAllowances = new uint256[](l);
        for (uint64 i = 0; i < l; ) {
            newSecrets[i] = secrets[i];
            newIds[i] = ids[i];
            newAllowances[i] = allowances[i];
            unchecked {
                i++;
            }
        }
        authentica.batchPushSecret(newSecrets, newIds, newAllowances);
        authentica.batchLockSecret(newSecrets);
        for (uint64 i = 0; i < l; ) {
            bool resultLocked = authentica.checkLocked(newSecrets[i]);
            assertEq(resultLocked, true);
            unchecked {
                i++;
            }
        }
    }

    function testBatchLockSecretUser(
        bytes32[] memory secrets,
        uint256[] memory ids,
        uint256[] memory allowances,
        uint64 l,
        address user
    ) public {
        vm.assume(user != address(this));
        vm.assume(
            secrets.length > l &&
            ids.length > l &&
            allowances.length > l&& 
            l > 0
        );
        bytes32[] memory newSecrets = new bytes32[](l);
        uint256[] memory newIds = new uint256[](l);
        uint256[] memory newAllowances = new uint256[](l);
        for (uint64 i = 0; i < l; ) {
            newSecrets[i] = secrets[i];
            newIds[i] = ids[i];
            newAllowances[i] = allowances[i];
            unchecked {
                i++;
            }
        }
        authentica.batchPushSecret(newSecrets, newIds, newAllowances);
        vm.prank(user);
        vm.expectRevert('Ownable: caller is not the owner');
        authentica.batchLockSecret(newSecrets);
    }

    function testBatchPushSecretMismatch(
        bytes32[] memory secrets,
        uint256[] memory ids,
        uint256[] memory allowances
    ) public {
        vm.expectRevert('Length mismatch.');
        vm.assume(
            secrets.length != ids.length ||
            secrets.length != allowances.length ||
            ids.length != allowances.length
        );
        vm.assume(secrets.length > 0);
        authentica.batchPushSecret(secrets, ids, allowances);
    }

    function testPushAndCheck(
        bytes32 secret,
        uint256 id,
        uint256 allowance,
        address user
    ) public {
        authentica.pushSecret(secret, id, allowance);
        vm.prank(user);
        uint256 resultId = authentica.checkId(secret);
        uint256 resultAllowance = authentica.checkAllowance(secret);
        bool resultLocked = authentica.checkLocked(secret);
        assertEq(resultId, id);
        assertEq(resultAllowance, allowance);
        assertEq(resultLocked, false);
    }

    function testPushLockAndCheck(
        bytes32 secret,
        uint256 id,
        uint256 allowance,
        address user
    ) public {
        authentica.pushSecret(secret, id, allowance);
        authentica.lockSecret(secret);
        vm.prank(user);
        uint256 resultId = authentica.checkId(secret);
        uint256 resultAllowance = authentica.checkAllowance(secret);
        bool resultLocked = authentica.checkLocked(secret);
        assertEq(resultId, id);
        assertEq(resultAllowance, allowance);
        assertEq(resultLocked, true);
    }

    function testLockPush(
        bytes32 secret,
        uint256 id,
        uint256 allowance
    ) public {
        authentica.lockSecret(secret);
        vm.expectRevert('Secret locked, cannot modify.');
        authentica.pushSecret(secret, id, allowance);
    }

    function testLockLock(
        bytes32 secret
    ) public {
        authentica.lockSecret(secret);
        authentica.lockSecret(secret);
        assertEq(authentica.checkLocked(secret), true);
    }

    function testBatchLockPush(
        bytes32[] memory secrets,
        uint256[] memory ids,
        uint256[] memory allowances,
        uint256 l,
        uint256 k
    ) public {
        vm.assume(
            secrets.length > l &&
            ids.length > l &&
            allowances.length > l&& 
            l > 0 &&
            l > k
        );
        bytes32[] memory newSecrets = new bytes32[](l);
        uint256[] memory newIds = new uint256[](l);
        uint256[] memory newAllowances = new uint256[](l);
        for (uint64 i = 0; i < l; ) {
            newSecrets[i] = secrets[i];
            newIds[i] = ids[i];
            newAllowances[i] = allowances[i];
            unchecked {
                i++;
            }
        }
        authentica.batchLockSecret(newSecrets);
        vm.expectRevert('Secret locked, cannot modify.');
        authentica.pushSecret(newSecrets[k], newIds[k], newAllowances[k]);
    }

    function testBatchLockLock(
        bytes32[] memory secrets
    ) public {
        require(secrets.length > 0);
        authentica.batchLockSecret(secrets);
        authentica.batchLockSecret(secrets);
        for (uint64 i = 0; i < secrets.length; ) {
            assertEq(authentica.checkLocked(secrets[i]), true);
            unchecked {
                i++;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                              COMMITMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    function testCommitmentBasicSanity(
        bytes32 secret,
        address user
    ) public {
        vm.prank(user);
        bytes32 resultId = authentica.checkCommitment(user, secret);
        assertEq(resultId, "");
    }

    function testPushCommitment(
        bytes32 secret,
        uint256 id,
        uint256 allowance,
        bytes32 commitment,
        address user
    ) public {
        vm.assume(allowance > 0);
        authentica.pushSecret(secret, id, allowance);
        vm.prank(user);
        authentica.pushCommitment(secret, commitment);
        assertEq(commitment, authentica.checkCommitment(address(user), secret));
    }

    function testPushCommitmentSpent(
        bytes32 secret,
        bytes32 commitment,
        address user
    ) public {
        vm.prank(user);
        vm.expectRevert('Secret already spent.');
        authentica.pushCommitment(secret, commitment);
    }

    function testFailPushCommitmentWrongEverything(
        bytes32 secret1,
        bytes32 secret2,
        uint256 id1,
        uint256 id2,
        uint256 allowance1,
        uint256 allowance2,
        bytes32 commitment1,
        bytes32 commitment2,
        address user1,
        address user2
    ) public {
        vm.assume(allowance1 > 0);
        vm.assume(allowance2 > 0);
        authentica.pushSecret(secret1, id1, allowance1);
        authentica.pushSecret(secret2, id2, allowance2);
        // If users and secrets are both equal commitments get overwritten.
        if (user1 == user2) {
            vm.assume(
                secret1 != secret2 &&
                commitment1 != commitment2
            );
        } else {
            vm.assume(
                commitment1 != commitment2
            );
        }
        vm.prank(user1);
        authentica.pushCommitment(secret1, commitment1);
        vm.prank(user2);
        authentica.pushCommitment(secret2, commitment2);
        assertEq(authentica.checkCommitment(user1, secret1), authentica.checkCommitment(user2, secret2));
    }

    function testBatchPushCommitment(
        bytes32[] memory secrets,
        uint256[] memory ids,
        uint256[] memory allowances,
        bytes32[] memory commitments,
        uint64 l,
        address user
    ) public {
        vm.assume(
            secrets.length > l &&
            ids.length > l &&
            allowances.length > l &&
            commitments.length > l &&
            l > 0
        );
        bytes32[] memory newSecrets = new bytes32[](l);
        uint256[] memory newIds = new uint256[](l);
        uint256[] memory newAllowances = new uint256[](l);
        bytes32[] memory newCommitments = new bytes32[](l);
        for (uint64 i = 0; i < l; ) {
            vm.assume(allowances[i] != 0);
            newSecrets[i] = secrets[i];
            for (uint64 j = 0; j < i; ) {
                // Writing to the same secret overwrites commitments, making the test fail
                vm.assume(newSecrets[i] != newSecrets[j]);
                unchecked {
                    j++;
                }
            }
            newIds[i] = ids[i];
            newAllowances[i] = allowances[i];
            newCommitments[i] = commitments[i];
            unchecked {
                i++;
            }
        }
        authentica.batchPushSecret(newSecrets, newIds, newAllowances);
        vm.prank(user);
        authentica.batchPushCommitment(newSecrets, newCommitments);
        for (uint64 i = 0; i < l; ) {
            assertEq(newCommitments[i], authentica.checkCommitment(user, newSecrets[i]));
            unchecked {
                i++;
            }
        }
    }

    function testBatchPushCommitmentSpent(
        bytes32[] memory secrets,
        bytes32[] memory commitments,
        uint256 l,
        address user
    ) public {
        vm.assume(
            secrets.length > l &&
            commitments.length > l && 
            l > 0
        );
        vm.expectRevert("Some secrets are already spent.");
        bytes32[] memory newSecrets = new bytes32[](l);
        bytes32[] memory newCommitments = new bytes32[](l);
        for (uint64 i = 0; i < l; ) {
            newSecrets[i] = secrets[i];
            newCommitments[i] = commitments[i];
            unchecked {
                i++;
            }
        }
        vm.prank(user);
        authentica.batchPushCommitment(newSecrets, newCommitments);
    }


    /*///////////////////////////////////////////////////////////////
                              REVEAL LOGIC
    //////////////////////////////////////////////////////////////*/
}
