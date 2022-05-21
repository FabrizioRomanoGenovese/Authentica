pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract Authentica is Ownable {

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event Commitment(
        address indexed from,
        bytes32 secret,
        bytes32 commitment
    );

    event BatchCommitment(
        address indexed from,
        bytes32[] secrets,
        bytes32[] commitments
    );

    /*///////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

/// @notice The owner of the contract publishes hashes of secrets
///    that allow to redeem a token with a certain id. 
///    As we focus on ERC1155 every secret has a given allowance.
/// @dev Hashed secrets are just keccak256 hashes of secrets.
///    Multiple secrets can point to the same tokenId. This is in
///    conformity with ERC1155 standard, where every token can be fungible.
///    A user with a secret can compute the hash and claim the tokens.
/// @notice To avoid getting snipered in the mempool, the user has to go through
///     a commit-reveal scheme.
/// @dev Commit is calculated by just hashing sender address XOR secret.

    mapping(bytes32 => uint256 ) private _tokenIds;
    mapping(bytes32 => uint256) private _allowancePerSecret;
    mapping(bytes32 => uint256 ) private _blockTime;
    mapping(address => mapping(bytes32 => bytes32)) private _commitments;

    uint256 private constant MINIMUM_DELAY = 1;
    
    /*///////////////////////////////////////////////////////////////
                              SECRET LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function checkId(
        bytes32 secret
    ) public view returns(uint256) {
        return _tokenIds[secret];
    }

    function checkAllowance(
        bytes32 secret
    ) public view returns(uint256) {
        return _allowancePerSecret[secret];
    }

    function _pushSecret(
        bytes32 secret,
        uint256 id,
        uint256 allowance
    ) onlyOwner internal virtual {
        _tokenIds[secret] = id;
        _allowancePerSecret[secret] = allowance;
    }

    function _batchPushSecret(
        bytes32[] memory secrets, 
        uint256[] memory ids, 
        uint256[] memory allowances
    ) onlyOwner internal virtual {
        uint256 secretsLength = secrets.length; 
        require(secretsLength >= ids.length, "Length mismatch.");
        require(secretsLength == allowances.length, "Length mismatch.");
        for (uint256 i = 0; i < secretsLength; ) {
            _tokenIds[secrets[i]] = ids[i];
            _allowancePerSecret[secrets[i]] = allowances[i];
            unchecked {
                i++;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                              COMMITMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    function checkCommitment(
        address person,
        bytes32 secret
    ) public view returns(bytes32) {
        return _commitments[person][secret];
    }

    function _pushCommitment (
        bytes32 secret,
        bytes32 commitment
    ) internal virtual {
        _commitments[_msgSender()][secret] = commitment;
        _blockTime[secret] = block.timestamp;
        emit Commitment(_msgSender(), secret, commitment);
    }

    function _batchPushCommitment (
        bytes32[] memory secrets,
        bytes32[] memory commitments
    ) internal virtual {
        uint256 secretsLength = secrets.length; 
        require(secretsLength == commitments.length, "Length mismatch.");
        for (uint256 i = 0; i < secretsLength; ) {
            _commitments[_msgSender()][secrets[i]] = commitments[i];
            _blockTime[secrets[i]] = block.timestamp;
            unchecked {
                i++;
            }
        }
        emit BatchCommitment(_msgSender(), secrets, commitments);
    }

    /*///////////////////////////////////////////////////////////////
                              REVEAL LOGIC
    //////////////////////////////////////////////////////////////*/

/// @notice Warnings in case of missing commitments are useless. If user calls
///    this function before committing it will be devoured in the dark forest.
/// @dev These functions do not deal with the transfer logic, which is up to the user.

    function _redeemArtwork (
        bytes32 key,
        uint256 amount
    ) internal virtual returns (uint256) {
        bytes32 secret = (keccak256(abi.encodePacked(key)));
        require(
            keccak256(
                abi.encodePacked(
                    _addressToBytes32(_msgSender())^key
                )
            ) == _commitments[_msgSender()][secret], "Reveal and commit do not match.");
        require(amount <= _allowancePerSecret[secret], "Reached allowance limit.");
        require(_blockTime[secret] + MINIMUM_DELAY <= block.timestamp, "Delay not passed.");
        _allowancePerSecret[secret] -= amount;
        return _tokenIds[secret];
    }

    function _redeemBatchArtwork (
        bytes32[] memory keys,
        uint256[] memory amounts
    ) internal virtual returns (uint256[] memory) {
        uint256 keysLength = keys.length;
        require(keysLength == amounts.length, "Length mismatch.");
        uint256[] memory ids;
        for (uint256 i = 0; i < keysLength; ) {
            bytes32 secret = (keccak256(abi.encodePacked(keys[i])));
            require(
                keccak256(
                    abi.encodePacked(
                        _addressToBytes32(_msgSender())^keys[i]
                    )
                ) == _commitments[_msgSender()][secret], "Reveal and commit do not match.");
            require(amounts[i] <= _allowancePerSecret[secret], "Reached allowance limit.");
            require(_blockTime[secret] + MINIMUM_DELAY <= block.timestamp, "Delay not passed.");
            _allowancePerSecret[secret] -= amounts[i];
            ids[i] = _tokenIds[secret];
            unchecked {
                i++;
            }
        }
        return ids;
    }

    /*///////////////////////////////////////////////////////////////
                              UTILS
    //////////////////////////////////////////////////////////////*/

    function _addressToBytes32 (address addr) pure private returns(bytes32) {
        return bytes32(uint256(uint160(addr)));
    }
}