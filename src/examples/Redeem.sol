pragma solidity 0.8.13;

import "solmate/tokens/ERC1155.sol";
import "../Authentica.sol";

/// @notice This contract must be deployed after the NFT contract.
/// @notice Artist should set up a specific custodian wallet.
/// @notice This contract should be set isApprovedForAll with respect to custodian.

abstract contract Redeem is Authentica, ERC1155 {

    ERC1155 token;

    constructor (address tokenAddress) {
        token = ERC1155(tokenAddress);
    }

    function pushSecret(
        uint256 id, 
        bytes32 secret, 
        uint256 allowance
    ) public {
        _pushSecret(id, secret, allowance);
    }

    function batchPushSecret(
        uint256[] memory ids, 
        bytes32[] memory secrets, 
        uint256[] memory allowances
    ) public {
        _batchPushSecret(ids, secrets, allowances);
    }

    function pushCommitment (
        bytes32 secret,
        bytes32 commitment
    ) internal {
        _pushCommitment(secret, commitment);
    }

    function batchPushCommitment (
        bytes32[] memory secrets,
        bytes32[] memory commitments
    ) internal {
        _batchPushCommitment(secrets, commitments);
    }

    function redeemArtwork (
        address custodian, 
        bytes32 key,
        uint256 amount, 
        bytes memory data
    ) public {
        uint256 id = _redeemArtwork(key, amount);
        token.safeTransferFrom(custodian, msg.sender, id, amount, data);
    }

    function redeemBatchArtwork (
        address custodian,
        bytes32[] memory keys,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        uint256[] memory ids = _redeemBatchArtwork(keys, amounts);
        token.safeBatchTransferFrom(custodian, msg.sender, ids, amounts, data);
    }

}
