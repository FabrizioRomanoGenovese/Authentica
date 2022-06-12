pragma solidity 0.8.13;


contract Authentica {

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
    mapping(bytes32 => bool) private _locked;

    mapping(bytes32 => uint256 ) private _blockTime;
    mapping(address => mapping(bytes32 => bytes32)) private _commitments;

    uint256 private constant MINIMUM_DELAY = 1;

    /*///////////////////////////////////////////////////////////////
                              SECRET LOGIC
    //////////////////////////////////////////////////////////////*/

/// @notice These functions should be protected by some form of ownership.

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
    
    function checkLocked(
        bytes32 secret
    ) public view returns(bool) {
        return _locked[secret];
    }

    function _pushSecret(
        bytes32 secret,
        uint256 id,
        uint256 allowance
    ) internal virtual {
    	require(id != 0, "Id0 is reserved for uninitialized secrets.");
        require(allowance != 0, "Cannot initialize with 0 allowance.");
    	require(!_locked[secret], "Secret locked, cannot modify.");
        _tokenIds[secret] = id;
        _allowancePerSecret[secret] = allowance;
    }

    function _lockSecret(
        bytes32 secret
    ) internal virtual {
	require(_tokenIds[secret] != 0, "You are trying to lock an uninitialized secret.");
	require(_allowancePerSecret[secret] != 0, "You are trying to lock an already spent secret.");
        _locked[secret] = true;
    }

/// @notice Same secret can show up multiple times
/// in the same array, and parameters get overwritten.
/// As best practice, check your array for repeated
/// entries before submitting. (doing it on-chain is too gas pricey).
    function _batchPushSecret(
        bytes32[] memory secrets,
        uint256[] memory ids,
        uint256[] memory allowances
    ) internal virtual {
        uint256 secretsLength = secrets.length;
        require(secretsLength > 0, "Empty array.");
        require(secretsLength == ids.length, "Length mismatch.");
        require(secretsLength == allowances.length, "Length mismatch.");
        for (uint256 i = 0; i < secretsLength; ) {
            bytes32 secret = secrets[i];
            require(ids[i] != 0, "Id0 is reserved for uninitialized secrets.");
            require(allowances[i] != 0, "Cannot initialize with 0 allowance.");
            require(!_locked[secret], "Some secrets are already locked, cannot modify.");
            _tokenIds[secret] = ids[i];
            _allowancePerSecret[secret] = allowances[i];
            unchecked {
                i++;
            }
        }
    }

    function _batchLockSecret(
        bytes32[] memory secrets
    ) internal virtual {
        uint256 secretsLength = secrets.length;
        require(secretsLength > 0, "Empty array.");
        for (uint256 i = 0; i < secretsLength; ) {
            require(_tokenIds[secrets[i]] != 0, "You are trying to lock an uninitialized secret.");
            require(_allowancePerSecret[secrets[i]] != 0, "You are trying to lock an already spent secret.");
            _locked[secrets[i]] = true;
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
        require(_allowancePerSecret[secret] !=0, "Secret already spent.");
        _commitments[msg.sender][secret] = commitment;
        _blockTime[secret] = block.timestamp;
        emit Commitment(msg.sender, secret, commitment);
    }

/// @notice Same secret can show up multiple times
/// in the same array, and parameters get overwritten.
/// As best practice, check your array for repeated
/// entries before submitting. (doing it on-chain is too gas pricey).
    function _batchPushCommitment (
        bytes32[] memory secrets,
        bytes32[] memory commitments
    ) internal virtual {
        uint256 secretsLength = secrets.length;
        require(secretsLength > 0, "Empty array.");
        require(secretsLength == commitments.length, "Length mismatch.");
        for (uint256 i = 0; i < secretsLength; ) {
            bytes32 secret = secrets[i];
            require(_allowancePerSecret[secret] !=0, "Some secrets are already spent.");
            _commitments[msg.sender][secret] = commitments[i];
            _blockTime[secret] = block.timestamp;
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
        bytes32 key
    ) internal virtual returns (uint256, uint256) {
        bytes32 secret = (keccak256(abi.encodePacked(key)));
        require(
            keccak256(
                abi.encodePacked(
                    _addressToBytes32(msg.sender)^key
                )
            ) == _commitments[msg.sender][secret], "Reveal and commit do not match.");
        require(_allowancePerSecret[secret] !=0, "Secret already spent.");
        require(_blockTime[secret] + MINIMUM_DELAY <= block.timestamp, "Delay not passed.");
        _locked[secret] = true;
        _allowancePerSecret[secret] = 0;
        return (_tokenIds[secret], _allowancePerSecret[secret]);
    }

    function _redeemBatchArtwork (
        bytes32[] memory keys
    ) internal virtual returns (uint256[] memory, uint256[] memory) {
        uint256 keysLength = keys.length;
        uint256[] memory ids;
        uint256[] memory amounts;
        for (uint256 i = 0; i < keysLength; ) {
            bytes32 secret = (keccak256(abi.encodePacked(keys[i])));
            require(
                keccak256(
                    abi.encodePacked(
                        _addressToBytes32(msg.sender)^keys[i]
                    )
                ) == _commitments[msg.sender][secret], "Reveal and commit do not match.");
            require(_allowancePerSecret[secret] !=0, "Some secrets are already spent.");
            require(_blockTime[secret] + MINIMUM_DELAY <= block.timestamp, "Delay not passed.");
            _locked[secret] = true;
            _allowancePerSecret[secret] = 0;
            ids[i] = _tokenIds[secret];
            amounts[i] = _allowancePerSecret[secret];
            unchecked {
                i++;
            }
        }
        return (ids,amounts);
    }

    /*///////////////////////////////////////////////////////////////
                              UTILS
    //////////////////////////////////////////////////////////////*/

    function _addressToBytes32 (address addr) pure private returns(bytes32) {
        return bytes32(uint256(uint160(addr)));
    }
}
