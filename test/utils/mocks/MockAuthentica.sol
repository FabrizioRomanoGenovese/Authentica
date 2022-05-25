// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "../../../src/Authentica.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract MockAuthentica is Authentica, Ownable {

    /*///////////////////////////////////////////////////////////////
                              SECRET LOGIC
    //////////////////////////////////////////////////////////////*/

    function pushSecret(
        bytes32 secret,
        uint256 id,
        uint256 allowance
    ) onlyOwner public {
        _pushSecret(secret, id, allowance);
    }

    function lockSecret(
        bytes32 secret
    ) onlyOwner public {
        _lockSecret(secret);
    }

    function batchPushSecret(
        bytes32[] memory secrets,
        uint256[] memory ids,
        uint256[] memory allowances
    ) onlyOwner public {
        _batchPushSecret(secrets, ids, allowances);
    }

    function batchLockSecret(
        bytes32[] memory secrets
    ) onlyOwner public {
        _batchLockSecret(secrets);
    }

    /*///////////////////////////////////////////////////////////////
                              COMMITMENT LOGIC
    //////////////////////////////////////////////////////////////*/

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

    /*///////////////////////////////////////////////////////////////
                              REVEAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function redeemArtwork (
        bytes32 key
    ) public returns (uint256, uint256) {
       return _redeemArtwork(key);
    }

    function redeemBatchArtwork (
        bytes32[] memory keys
    ) public returns (uint256[] memory, uint256[] memory) {
        return _redeemBatchArtwork(keys);
   }

}