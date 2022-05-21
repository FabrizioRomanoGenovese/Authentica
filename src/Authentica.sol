pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract Authentica is Ownable {

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event Commitment(
        address indexed from,
        uint256 id,
        bytes32 commitment
    );

    event BatchCommitment(
        address indexed from,
        uint256[] ids,
        bytes32[] commitments
    );

    /*///////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

/// @notice The owner of the contract publishes hashes of secrets
///    that allow to redeem a token with a certain id. 
///    As we focus on ERC1155 every secret has a given allowance.
/// @dev Hashed secrets are just keccak256 hashes of secrets.
///    A user with a secret can compute the hash and claim the tokens.
/// @notice To avoid getting snipered in the mempool, the user has to go through
///     a commit-reveal scheme.
/// @dev Commit is calculated by just hashing sender address XOR secret.

    mapping(uint256 => bytes32) private _hashedSecrets;
    mapping(uint256 => uint256) private _allowancePerSecret;
    mapping(address => mapping(uint256 => bytes32)) private _commitments;

    /*///////////////////////////////////////////////////////////////
                              SECRET LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function checkSecret(
        uint256 id
    ) public view returns(bytes32) {
        return _hashedSecrets[id];
    }

    function checkAllowance(
        uint256 id
    ) public view returns(uint256) {
        return _allowancePerSecret[id];
    }

    function _pushSecret(
        uint256 id, 
        bytes32 secret, 
        uint256 allowance
    ) onlyOwner internal virtual {
        _hashedSecrets[id] = secret;
        _allowancePerSecret[id] = allowance;
    }

    function _batchPushSecret(
        uint256[] memory ids, 
        bytes32[] memory secrets, 
        uint256[] memory allowances
    ) onlyOwner internal virtual {
        uint256 idsLength = ids.length; 
        require(idsLength == secrets.length, "LENGTH_MISMATCH");
        require(idsLength == allowances.length, "LENGTH_MISMATCH");
        for (uint256 i = 0; i < idsLength; ) {
            _hashedSecrets[ids[i]] = secrets[i];
            _allowancePerSecret[ids[i]] = allowances[i];
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
        uint256 id
    ) public view returns(bytes32) {
        return _commitments[person][id];
    }

    function _pushCommitment (
        uint256 id, 
        bytes32 commitment
    ) internal virtual {
        _commitments[msg.sender][id] = commitment;
        emit Commitment(msg.sender, id, commitment);
    }

    function _batchPushCommitment (
        uint256[] memory ids, 
        bytes32[] memory commitments
    ) internal virtual {
        uint256 commitmentsLength = commitments.length; 
        require(commitmentsLength == ids.length, "LENGTH_MISMATCH");
        for (uint256 i = 0; i < commitmentsLength; ) {
            _commitments[msg.sender][ids[i]] = commitments[i];
            unchecked {
                i++;
            }
        }
        emit BatchCommitment(msg.sender, ids, commitments);
    }

    /*///////////////////////////////////////////////////////////////
                              REVEAL LOGIC
    //////////////////////////////////////////////////////////////*/

/// @notice Warnings in case of missing commitments are useless. If user calls
///    this function before committing it will be devoured in the dark forest.
/// @dev These functions do not deal with the transfer logic, which is up to the user.

    function _redeemArtwork (
        uint256 id, 
        uint256 amount, 
        bytes32 secret
    ) internal virtual {
        require(keccak256(abi.encodePacked(secret)) == _hashedSecrets[id], "wrong secret");
        require(keccak256(abi.encodePacked(_addressToBytes32(msg.sender)^secret)) == _commitments[msg.sender][id]);
        require(amount <= _allowancePerSecret[id]);
        _allowancePerSecret[id] -= amount;
    }

    function _redeemBatchArtwork (
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes32[] memory secrets
    ) internal virtual {
        uint256 secretsLength = secrets.length; 
        require(secretsLength == ids.length, "LENGTH_MISMATCH");
        for (uint256 i = 0; i < secretsLength; ) {
            require(keccak256(abi.encodePacked(secrets[i])) == _hashedSecrets[ids[i]], "wrong secret");
            require(keccak256(abi.encodePacked(_addressToBytes32(msg.sender)^secrets[i])) == _commitments[msg.sender][ids[i]]);
            _allowancePerSecret[ids[i]] -= amounts[i];

            unchecked {
                i++;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                              UTILS
    //////////////////////////////////////////////////////////////*/

    function _addressToBytes32 (address addr) pure private returns(bytes32) {
        return bytes32(uint256(uint160(addr)));
    }
}