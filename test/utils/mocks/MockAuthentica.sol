// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "../../../src/Authentica.sol";

contract MockAuthentica is Authentica {

    /*///////////////////////////////////////////////////////////////
                              SECRET LOGIC
    //////////////////////////////////////////////////////////////*/

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