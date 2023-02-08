// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract MultiSig {

    address[] public signers;
    address[] public guardians;
    uint256 public expiration;
    uint256 public quorum;

    struct Transaction {
        address to;
        uint256 amount;
        bytes data;
        bool successful;
        uint256 signs;
    }

    Transaction[] public transactions;

    mapping(uint256 => mapping(address => bool)) public confirmations;

    ////////////////////////
    //   Events
    ////////////////////////

    event Deposit(address indexed sender, uint amount, uint balance);

    event TxOffered(
        address indexed owner,
        uint indexed txId,
        address indexed to,
        uint value,
        bytes data
    );

    event TxApproved(address indexed owner, uint indexed txId);
    event TxRevoked(address indexed owner, uint indexed txId);
    event TxExecuted(address indexed owner, uint indexed txId);

    event QuorumSet(uint256 quorum);

    ////////////////////////
    //   Checks
    ////////////////////////

    modifier executedCheck(uint256 _txId) {
        if(transactions[_txId].successful == true) revert();
        _;
    }

    modifier idCheck(uint256 _txId) {
        if(_txId > transactions.length) revert();
        _;
    }

    modifier onlySigner() {
        if(isSigner() == false) revert();
        _;
    }

    function isSigner() public view returns (bool) {
        for (uint256 i; i < signers.length;) {
            if (signers[i] == msg.sender) {
                return true;
            }
            unchecked {
                ++i;
            }
        }
        return false;
    }

    modifier onlyGuardian() {
        if(isGuardian() == false) revert();
        _;
    }

    function isGuardian() public view returns (bool) {
        for (uint256 i; i < guardians.length;) {
            if (guardians[i] == msg.sender) {
                return true;
            }
            unchecked {
                ++i;
            }
        }
        return false;
    }

    ////////////////////////
    //   Constructor
    ////////////////////////

    constructor(address[] memory _signers, uint256 _quorum) {
        if(_quorum > _signers.length) revert();
        for (uint i; i < _signers.length;) {
            address signer = _signers[i];
            if(signer == address(0)) revert();
            signers.push(signer);
            unchecked {
                ++i;
            }
        }
        quorum = _quorum;
    }

    ////////////////////////
    //   Tx's
    ////////////////////////

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function offerTx(address _to, uint256 _amount, bytes memory _data) public onlySigner {
        uint256 txId = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                amount: _amount,
                data: _data,
                successful: false,
                signs: 0
            })
        );

        emit TxOffered(msg.sender, txId, _to, _amount, _data);
    }

    function approveTx(uint256 _txId) public onlySigner executedCheck(_txId) idCheck(_txId) {
        if(confirmations[_txId][msg.sender] == true) revert();

        Transaction storage transaction = transactions[_txId];
        confirmations[_txId][msg.sender] == true;
        transaction.signs = transaction.signs + 1;
        
        emit TxApproved(msg.sender, _txId);
    }

    function revokeTx(uint256 _txId) public onlySigner executedCheck(_txId) idCheck(_txId) {

        Transaction storage transaction = transactions[_txId];
        confirmations[_txId][msg.sender] == false;
        transaction.signs = transaction.signs - 1;

        emit TxRevoked(msg.sender, _txId);
    }

    function executeTx(uint256 _txId) public onlySigner executedCheck(_txId) idCheck(_txId) {
        Transaction storage transaction = transactions[_txId];
        if(transaction.signs < quorum) revert();

        transaction.successful = true;

        (bool success, ) = transaction.to.call{value: transaction.amount}(
            transaction.data
        );
        require(success, "tx failed");

        emit TxExecuted(msg.sender, _txId);
    }

    ////////////////////////
    //   Signer Controls
    ////////////////////////

    function setSigner(address _signer) public onlySigner {
        signers.push(_signer);
    }

    function removeSigner(uint16 i) public onlySigner {
        signers[i] = signers[signers.length - 1];
        signers.pop();
    }

    function setQuorum(uint256 _quorum) public virtual onlySigner {
        quorum = uint120(_quorum);
        emit QuorumSet(_quorum);
    }

    ////////////////////////
    //   Social Recovery
    ////////////////////////

    function emergency(uint256 _expiration) public onlyGuardian {
        if(_expiration > 86400) revert();
        expiration = _expiration + block.timestamp;
    }

    function recover() public onlyGuardian {
        if(expiration > block.timestamp) revert();
        if(expiration == 0) revert();

        signers.push(msg.sender);
    }

    function setGuardian(address[] memory _guardians) public onlySigner {
        guardians = _guardians;
        for (uint i; i < _guardians.length;) {
            address guardian = _guardians[i];
            if(guardian == address(0)) revert();
            guardians.push(guardian);
            unchecked {
                ++i;
            }
        }
    }

    function setExtension(uint256 _extension) external onlySigner {
        if(block.timestamp >= expiration) revert();
        expiration = block.timestamp + timeLeft() + _extension;
    }

    function timeLeft() public view returns (uint256) {
        return expiration - block.timestamp;
    }
}
