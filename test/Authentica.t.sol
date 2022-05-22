// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;


import "forge-std/Test.sol";
import "../src/Authentica.sol";

contract MockAuthentica is Authentica {

    function pushSecret(
        bytes32 secret, 
        uint256 id, 
        uint256 allowance
    ) public {
        _pushSecret(secret, id, allowance);
    }

    function batchPushSecret(
        bytes32[] memory secrets, 
        uint256[] memory ids, 
        uint256[] memory allowances
    ) public {
        _batchPushSecret(secrets, ids, allowances);
    }

    function pushCommitment (
        bytes32 secret,
        bytes32 commitment
    ) public {
        _pushCommitment(secret, commitment);
    }

    function batchPushCommitment (
        bytes32[] memory secrets,
        bytes32[] memory commitments
    ) public {
        _batchPushCommitment(secrets, commitments);
    }

    function redeemArtwork (
        bytes32 key,
        uint256 amount
    ) public returns (uint256) {
       return _redeemArtwork(key, amount);
    }

    function redeemBatchArtwork (
        bytes32[] memory keys,
        uint256[] memory amounts
    ) public returns (uint256[] memory) {
        return _redeemBatchArtwork(keys, amounts);
   }

}

contract AuthenticaUser {
    MockAuthentica authentica;

    constructor(MockAuthentica cntrct) {
        authentica = cntrct;
    }

    function callCheckId(
        bytes32 secret
    ) public view returns(uint256) {
        return authentica.checkId(secret);
    }

    function callPushSecret(
        bytes32 secret, 
        uint256 id, 
        uint256 allowance
    ) public {
        authentica.pushSecret(secret, id, allowance);
    }

    function callBatchPushSecret(
        bytes32[] memory secrets, 
        uint256[] memory ids, 
        uint256[] memory allowances
    ) public {
        authentica.batchPushSecret(secrets, ids, allowances);
    }

}

contract AuthenticaOwner {
    MockAuthentica authentica;

    constructor() {
        authentica = new MockAuthentica();
    }

    function authenticaAddress() public view returns(MockAuthentica) {
        return authentica;
    }

    function callOwner() public view returns (address) {
        return authentica.owner();
    }

    function callPushSecret(
        bytes32 secret, 
        uint256 id, 
        uint256 allowance
    ) public {
        authentica.pushSecret(secret, id, allowance);
    }

    function callBatchPushSecret(
        bytes32[] memory secrets, 
        uint256[] memory ids, 
        uint256[] memory allowances
    ) public {
        authentica.batchPushSecret(secrets, ids, allowances);
    }
}

contract AuthenticaTest is AuthenticaOwner, Test {
    AuthenticaOwner internal authenticaOwner;
    AuthenticaUser internal authenticaUser;

    function setUp() public {
        authenticaOwner = new AuthenticaOwner();
        authenticaUser = new AuthenticaUser(authenticaOwner.authenticaAddress());
    }

    function testOwnership() public {
        assertEq(address(authenticaOwner), authenticaOwner.callOwner());
    }


    function testPushSecretOwner(
        bytes32 secret, 
        uint256 id, 
        uint256 allowance
    ) public {
        authenticaOwner.callPushSecret(secret, id, allowance);
    }

    function testPushSecretUser(
        bytes32 secret, 
        uint256 id, 
        uint256 allowance
    ) public {
        vm.expectRevert('Ownable: caller is not the owner');
        authenticaUser.callPushSecret(secret, id, allowance);
    }

    // // Fails due to many global rejects
    // // function testBatchPushSecretOwner(
    // //     bytes32[] memory secrets, 
    // //     uint256[] memory ids, 
    // //     uint256[] memory allowances
    // // ) public {
    // //     vm.assume(secrets.length <= 10);
    // //     vm.assume(secrets.length == ids.length);
    // //     vm.assume(secrets.length == allowances.length);
    // //     authenticaOwner.batchPushSecret(secrets, ids, allowances);
    // // }

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
        authenticaOwner.callBatchPushSecret(secrets, ids, allowances);
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
        authenticaOwner.callBatchPushSecret(secrets, ids, allowances);
    }

    function testBatchPushSecretMismatch2() public {
        vm.expectRevert('Length mismatch.');
        bytes32[] memory secrets = new bytes32[](3);
        secrets[0] = "hello";
        secrets[1] = "world";
        secrets[2] = "everyone";
        uint256[] memory ids = new uint256[](2);
        ids[0] = 4;
        ids[1] = 345989;
        uint256[] memory allowances = new uint256[](3);
        allowances[0] = 47582;
        allowances[1] = 3928;
        allowances[2] = 274;
        authenticaOwner.callBatchPushSecret(secrets, ids, allowances);
    }


    function testBatchPushSecretMismatch3() public {
        vm.expectRevert('Length mismatch.');
        bytes32[] memory secrets = new bytes32[](3);
        secrets[0] = "hello";
        secrets[1] = "world";
        secrets[2] = "everyone";
        uint256[] memory ids = new uint256[](3);
        ids[0] = 4;
        ids[1] = 345989;
        ids[2] = 84795;
        uint256[] memory allowances = new uint256[](2);
        allowances[0] = 47582;
        allowances[1] = 274;
        authenticaOwner.callBatchPushSecret(secrets, ids, allowances);
    }

    function testBatchPushSecretUser() public {
        vm.expectRevert('Ownable: caller is not the owner');
        bytes32[] memory secrets = new bytes32[](2);
        secrets[0] = "hello";
        secrets[1] = "world";
        uint256[] memory ids = new uint256[](2);
        ids[0] = 4;
        ids[1] = 345989;
        uint256[] memory allowances = new uint256[](2);
        allowances[0] = 47582;
        allowances[1] = 3928;
        authenticaUser.callBatchPushSecret(secrets, ids, allowances);
    }

    function testPushAndCheck() public {
        authenticaOwner.callPushSecret("hello", 345, 41);
        uint256 result = authenticaUser.callCheckId("hello");
        assertEq(result, 345);
    }

    function testPushAndCheck(
        bytes32 secret, 
        uint256 id, 
        uint256 allowance
    ) public {
        authenticaOwner.callPushSecret(secret, id, allowance);
        uint256 result = authenticaUser.callCheckId(secret);
        assertEq(result, id);
    }

}




 