pragma solidity 0.8.13;

import "./Authentica.sol";

contract AuthenticaTimed is Authentica {

    /*///////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(bytes32 => uint256) private _blockTime;

    /*///////////////////////////////////////////////////////////////
                              SECRET LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function _pushSecret(
        bytes32 secret,
        uint256 id,
        uint256 allowance,
        uint256 blockTime
    ) onlyOwner internal {
        _pushSecret(secret, id, allowance);
        _blockTime[secret] = blockTime;
    }

    function _batchPushSecret(
        bytes32[] memory secrets, 
        uint256[] memory ids, 
        uint256[] memory allowances,
        uint256[] memory blockTimes
    ) onlyOwner internal {
        _batchPushSecret(secrets, ids, allowances);
        uint256 secretsLength = secrets.length; 
        require(secretsLength == blockTimes.length, "Length mismatch.");
        for (uint256 i = 0; i < secretsLength; ) {
            _blockTime[secrets[i]] = blockTimes[i];
            unchecked {
                i++;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                              REVEAL LOGIC
    //////////////////////////////////////////////////////////////*/

/// @notice Warnings in case of missing commitments are useless. If user calls
///    this function before committing it will be devoured in the dark forest.
/// @dev These functions do not deal with the transfer logic, which is up to the user.

    function _redeemArtwork (
        bytes32 key
    ) internal override returns (uint256, uint256) {
        bytes32 secret = (keccak256(abi.encodePacked(key)));
        require(block.timestamp <= _blockTime[secret], "Secret expired");
        return super._redeemArtwork(key);
    }

    function _redeemBatchArtwork (
        bytes32[] memory keys
    ) internal override  returns (uint256[] memory, uint256[] memory) {
        bytes32 secret;
        for (uint256 i = 0; i < keys.length; ) {
            secret = (keccak256(abi.encodePacked(keys[i])));
            require(block.timestamp <= _blockTime[secret], "Secret expired");
            unchecked {
                i++;
            }
        }
        return super._redeemBatchArtwork(keys);
    }

}