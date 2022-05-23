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
    
    function testPushSecretOwner(
        bytes32 secret, 
        uint256 id, 
        uint256 allowance
    ) public {
        authentica.pushSecret(secret, id, allowance);
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

    function testBatchPushSecretOwner() public {
        bytes32[] memory secrets = new bytes32[](3);
            secrets[0] = "hello";
            secrets[1] = "world";
            secrets[2] = "everyone";
        uint256[] memory ids = new uint256[](3);
            ids[0] = 4;
            ids[1] = 345989;
            ids[2] = 84795;
        uint256[] memory allowances = new uint256[](3);
            allowances[0] = 47582;
            allowances[1] = 3928;
            allowances[2] = 274;
        authentica.batchPushSecret(secrets, ids, allowances);
    }

    function testBatchPushSecretOwner(
        bytes32[] memory secrets, 
        uint256[] memory ids, 
        uint256[] memory allowances,
        uint64 l
    ) public {
        vm.assume(secrets.length > l);
        vm.assume(ids.length > l);
        vm.assume(allowances.length > l);
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

    function testBatchPushSecretUser() public {
        vm.expectRevert('Ownable: caller is not the owner');
        vm.prank(address(0xBEEF));
        bytes32[] memory secrets = new bytes32[](2);
            secrets[0] = "hello";
            secrets[1] = "world";
        uint256[] memory ids = new uint256[](2);
            ids[0] = 4;
            ids[1] = 345989;
        uint256[] memory allowances = new uint256[](2);
            allowances[0] = 47582;
            allowances[1] = 3928;
        authentica.batchPushSecret(secrets, ids, allowances);
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
            allowances.length > l
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

    function testBatchPushSecretMismatch() public {
        vm.expectRevert('Length mismatch.');
        bytes32[] memory secrets = new bytes32[](2);
            secrets[0] = "hello";
            secrets[1] = "world";
        uint256[] memory ids = new uint256[](3);
            ids[0] = 4;
            ids[1] = 345989;
            ids[2] = 84795;
        uint256[] memory allowances = new uint256[](3);
            allowances[0] = 47582;
            allowances[1] = 3928;
            allowances[2] = 274;
        authentica.batchPushSecret(secrets, ids, allowances);
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
        authentica.batchPushSecret(secrets, ids, allowances);
    }

    function testPushAndCheck() public {
        authentica.pushSecret("secret", 666, 42);
        vm.prank(address(0xBEEF));
        uint256 result = authentica.checkId("secret");
        assertEq(result, 666);
    }

    function testPushAndCheck(
        bytes32 secret, 
        uint256 id, 
        uint256 allowance,
        address user
    ) public {
        authentica.pushSecret(secret, id, allowance);
        vm.prank(user);
        uint256 result = authentica.checkId(secret);
        assertEq(result, id);
    }

    /*///////////////////////////////////////////////////////////////
                              COMMITMENT LOGIC
    //////////////////////////////////////////////////////////////*/
    function testPushCommitment() public {
        vm.prank(address(0xBEEF));
        authentica.pushCommitment("secret", "commitment");
        assertEq("commitment", authentica.checkCommitment(address(0xBEEF), "secret"));
    }

    function testPushCommitment(
        bytes32 secret,
        bytes32 commitment,
        address user
    ) public {
        vm.prank(user);
        authentica.pushCommitment(secret, commitment);
        assertEq(commitment, authentica.checkCommitment(address(user), secret));
    }

    function testFailPushCommitmentWrongSecret() public {
        vm.prank(address(0xBEEF));
        authentica.pushCommitment("secret1", "commitment1");
        vm.prank(address(0xBEEF));
        authentica.pushCommitment("secret2", "commitment2");
        assertEq("commitment2", authentica.checkCommitment(address(0xBEEF), "secret1"));
    }

    function testFailPushCommitmentWrongAddress() public {
        vm.prank(address(0xBEEF));
        authentica.pushCommitment("secret1", "commitment1");
        vm.prank(address(0xDEADBEEF));
        authentica.pushCommitment("secret2", "commitment2");
        assertEq(authentica.checkCommitment(address(0xBEEF), "secret1"), authentica.checkCommitment(address(0xDEADBEEF), "secret1"));
    }

    function testPushCommitmentOverwrite() public {
        vm.prank(address(0xBEEF));
        authentica.pushCommitment("secret1", "commitment1");
        vm.prank(address(0xBEEF));
        authentica.pushCommitment("secret1", "commitment2");
        assertEq("commitment2", authentica.checkCommitment(address(0xBEEF), "secret1"));
    }

    function testFailPushCommitmentWrongEverything(
        bytes32 secret1,
        bytes32 secret2,
        bytes32 commitment1,
        bytes32 commitment2,
        address user1,
        address user2
    ) public {
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

    function testBatchPushCommitment() public {
        vm.prank(address(0xBEEF));
        bytes32[] memory secrets = new bytes32[](2);
            secrets[0] = "secret1";
            secrets[1] = "secret2";
        bytes32[] memory commitments = new bytes32[](2);
            commitments[0] = "commitment1";
            commitments[1] = "commitment2";
        authentica.batchPushCommitment(secrets, commitments);
        assertEq(commitments[0], authentica.checkCommitment(address(0xBEEF), secrets[0]));
        assertEq(commitments[1], authentica.checkCommitment(address(0xBEEF), secrets[1]));
    }

    function testBatchPushCommitment(
        bytes32[] memory secrets,
        bytes32[] memory commitments,
        uint64 l,
        address user
    ) public {
        vm.assume(
            secrets.length > l &&
            commitments.length > l
        );
        bytes32[] memory newSecrets = new bytes32[](l);
        bytes32[] memory newCommitments = new bytes32[](l);
        for (uint64 i = 0; i < l; ) {
            newSecrets[i] = secrets[i];
            for (uint64 j = 0; j < i; ) {
                // Writing to the same secret overwrites commitments, making the test fail
                vm.assume(newSecrets[i] != newSecrets[j]);
                unchecked {
                    j++;
                }
            }
            newCommitments[i] = commitments[i];
            unchecked {
                i++;
            }
        }
        vm.prank(user);
        authentica.batchPushCommitment(newSecrets, newCommitments);
        for (uint64 i = 0; i < l; ) {
            assertEq(newCommitments[i], authentica.checkCommitment(user, newSecrets[i]));
            unchecked {
                i++;
            }
        }    
    }   
}