pragma solidity 0.8.13;

//import "solmate/tokens/ERC1155.sol";
import {MockERC1155} from "solmate/test/utils/mocks/MockERC1155.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

import "../Authentica.sol";

/// @notice This contract must be deployed after the NFT contract.
/// @notice Artist should set up a specific custodian wallet.
/// @notice This contract should be set isApprovedForAll with respect to custodian.

contract Redeem is Authentica, MockERC1155, Ownable {

    MockERC1155 token;

    constructor (address tokenAddress) {
        token = MockERC1155(tokenAddress);
    }

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
        address custodian, 
        bytes32 key,
        bytes memory data
    ) public {
        uint256 id;
        uint256 amount;
        (id,amount) = _redeemArtwork(key);
        token.safeTransferFrom(custodian, msg.sender, id, amount, data);
    }

    function redeemBatchArtwork (
        address custodian,
        bytes32[] memory keys,
        bytes memory data
    ) public {
        uint256[] memory ids;
        uint256[] memory amounts;
        (ids,amounts) = _redeemBatchArtwork(keys);
        token.safeBatchTransferFrom(custodian, msg.sender, ids, amounts, data);
    }
}