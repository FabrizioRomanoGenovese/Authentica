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

    mapping(bytes32 => uint256 ) private _hashedSecrets;
    mapping(bytes32 => uint256) private _allowancePerSecret;
    mapping(address => mapping(bytes32 => bytes32)) private _commitments;

    /*///////////////////////////////////////////////////////////////
                              SECRET LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function checkSecret(
        bytes32 secret
    ) public view returns(uint256) {
        return _hashedSecrets[secret];
    }

    function checkAllowance(
        bytes32 secret
    ) public view returns(uint256) {
        return _allowancePerSecret[secret];
    }

    function _pushSecret(
        uint256 id, 
        bytes32 secret, 
        uint256 allowance
    ) onlyOwner internal virtual {
        _hashedSecrets[secret] = id;
        _allowancePerSecret[secret] = allowance;
    }

    function _batchPushSecret(
        uint256[] memory ids, 
        bytes32[] memory secrets, 
        uint256[] memory allowances
    ) onlyOwner internal virtual {
        uint256 secretsLength = secrets.length; 
        require(secretsLength >= secrets.length, "LENGTH_MISMATCH");
        require(secretsLength == allowances.length, "LENGTH_MISMATCH");
        for (uint256 i = 0; i < secretsLength; ) {
            _hashedSecrets[secrets[i]] = ids[i];
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
        _commitments[msg.sender][secret] = commitment;
        emit Commitment(msg.sender, secret, commitment);
    }

    function _batchPushCommitment (
        bytes32[] memory secrets,
        bytes32[] memory commitments
    ) internal virtual {
        uint256 secretsLength = secrets.length; 
        require(secretsLength == commitments.length, "LENGTH_MISMATCH");
        for (uint256 i = 0; i < secretsLength; ) {
            _commitments[msg.sender][secrets[i]] = commitments[i];
            unchecked {
                i++;
            }
        }
        emit BatchCommitment(msg.sender, secrets, commitments);
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
        //require(keccak256(abi.encodePacked(key)) == _hashedSecrets[secrets], "wrong secret");
        bytes32 secret = (keccak256(abi.encodePacked(key)));
        require(keccak256(abi.encodePacked(_addressToBytes32(msg.sender)^key)) == _commitments[msg.sender][secret]);
        require(amount <= _allowancePerSecret[secret]);
        _allowancePerSecret[secret] -= amount;
        return _hashedSecrets[secret];
    }

    function _redeemBatchArtwork (
        bytes32[] memory keys,
        uint256[] memory amounts
    ) internal virtual returns (uint256[] memory) {
        uint256 keysLength = keys.length;
        require(keysLength == amounts.length, "LENGTH_MISMATCH");
        uint256[] memory ids;
        for (uint256 i = 0; i < keysLength; ) {
            bytes32 secret = (keccak256(abi.encodePacked(keys[i])));
            require(keccak256(abi.encodePacked(_addressToBytes32(msg.sender)^keys[i])) == _commitments[msg.sender][secret]);
            _allowancePerSecret[secret] -= amounts[i];
            ids[i] = _hashedSecrets[secret];
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