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

    function redeemArtwork (
        address custodian, 
        uint256 id, 
        uint256 amount, 
        bytes memory data, 
        bytes32 secret
    ) public {
        _redeemArtwork(id, amount, secret);
        token.safeTransferFrom(custodian, msg.sender, id, amount, data);
    }

    function redeemBatchArtwork (
        address custodian,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data,
        bytes32[] memory secrets
    ) public {
        _redeemBatchArtwork(ids, amounts, secrets);
        token.safeBatchTransferFrom(custodian, msg.sender, ids, amounts, data);
    }

}