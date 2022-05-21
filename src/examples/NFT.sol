// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "solmate/tokens/ERC1155.sol";
import "openzeppelin-contracts/contracts/access/AccessControl.sol";

/// @notice A standard ERC1155 contract with minter roles.
contract NFT is AccessControl, ERC1155 {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string private _uri;

    constructor() {
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /*///////////////////////////////////////////////////////////////
                            URI LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view override returns (string memory) {
        return _uri;
    }

    function setUri(string memory newUri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _uri = newUri;
    }

    /*///////////////////////////////////////////////////////////////
                            INTERFACE LOGIC
    //////////////////////////////////////////////////////////////*/

/// @notice necessary as we inherit from both open-zeppelin and solmate

    function supportsInterface(bytes4 interfaceId) public pure override(AccessControl, ERC1155) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*///////////////////////////////////////////////////////////////
                            MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        _mint(to, id, amount, data);
    }

    function batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        _batchMint(to, ids, amounts, data);
    }
}