// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Proxy Contract
contract TippingProxy {
    // Storage slot for implementation address
    bytes32 private constant IMPLEMENTATION_SLOT = 
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    // Admin address slot
    bytes32 private constant ADMIN_SLOT = 
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    constructor() {
        _setAdmin(msg.sender);
    }

    modifier onlyAdmin() {
        require(msg.sender == _getAdmin(), "Only admin can call");
        _;
    }

    function upgradeTo(address newImplementation) external onlyAdmin {
        require(newImplementation != address(0), "Invalid implementation");
        require(newImplementation.code.length > 0, "Not a contract");
        _setImplementation(newImplementation);
    }

    function implementation() external view returns (address) {
        return _getImplementation();
    }

    fallback() external payable {
        address impl = _getImplementation();
        require(impl != address(0), "Implementation not set");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    receive() external payable {}

    function _setImplementation(address newImplementation) private {
        assembly {
            sstore(IMPLEMENTATION_SLOT, newImplementation)
        }
    }

    function _getImplementation() private view returns (address impl) {
        assembly {
            impl := sload(IMPLEMENTATION_SLOT)
        }
    }

    function _setAdmin(address newAdmin) private {
        assembly {
            sstore(ADMIN_SLOT, newAdmin)
        }
    }

    function _getAdmin() private view returns (address admin) {
        assembly {
            admin := sload(ADMIN_SLOT)
        }
    }
}

// Implementation Contract
contract TippingImplementation is ReentrancyGuard, Pausable, AccessControl {
    using Address for address payable;

    // Role definitions
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    // Events
    event CreatorRegistered(address indexed creator, string name, uint256 timestamp);
    event CreatorVerified(address indexed creator, address indexed verifier);
    event TipSent(address indexed from, address indexed to, uint256 amount, string message);
    event WithdrawnTips(address indexed creator, uint256 amount);
    event RateLimitUpdated(uint256 newLimit);
    event BatchTipSent(address indexed from, address[] to, uint256[] amounts);

    // Structs
    struct Creator {
        string name;
        bool isRegistered;
        bool isVerified;
        uint256 totalTipsReceived;
        uint256 lastWithdrawalTime;
        uint256 registrationTime;
    }

    struct RateLimit {
        uint256 amount;
        uint256 lastResetTime;
        uint256 currentUsage;
    }

    // State variables
    mapping(address => Creator) public creators;
    mapping(address => uint256) public creatorBalance;
    mapping(address => RateLimit) public rateLimits;
    
    uint256 public withdrawalCooldown;
    uint256 public maxTipAmount;
    uint256 public constant RATE_LIMIT_PERIOD = 1 days;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        
        withdrawalCooldown = 1 hours;
        maxTipAmount = 1 ether;
    }

    // Modifiers
    modifier onlyRegisteredCreator() {
        require(creators[msg.sender].isRegistered, "Not a registered creator");
        _;
    }

    modifier withinRateLimit(uint256 amount) {
        RateLimit storage limit = rateLimits[msg.sender];
        if (block.timestamp >= limit.lastResetTime + RATE_LIMIT_PERIOD) {
            limit.currentUsage = 0;
            limit.lastResetTime = block.timestamp;
        }
        require(limit.currentUsage + amount <= maxTipAmount, "Rate limit exceeded");
        limit.currentUsage += amount;
        _;
    }

    // Admin functions
    function setMaxTipAmount(uint256 newLimit) external onlyRole(ADMIN_ROLE) {
        maxTipAmount = newLimit;
        emit RateLimitUpdated(newLimit);
    }

    function verifyCreator(address creator) external onlyRole(MODERATOR_ROLE) {
        require(creators[creator].isRegistered, "Creator not registered");
        creators[creator].isVerified = true;
        emit CreatorVerified(creator, msg.sender);
    }

    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // Creator functions
    function registerCreator(string calldata name) external {
        require(!creators[msg.sender].isRegistered, "Already registered");
        require(bytes(name).length > 0 && bytes(name).length <= 50, "Invalid name length");
        
        creators[msg.sender] = Creator({
            name: name,
            isRegistered: true,
            isVerified: false,
            totalTipsReceived: 0,
            lastWithdrawalTime: 0,
            registrationTime: block.timestamp
        });
        
        emit CreatorRegistered(msg.sender, name, block.timestamp);
    }

    function withdrawTips() external nonReentrant onlyRegisteredCreator whenNotPaused {
        uint256 amount = creatorBalance[msg.sender];
        require(amount > 0, "No tips to withdraw");
        require(
            block.timestamp >= creators[msg.sender].lastWithdrawalTime + withdrawalCooldown,
            "Cooldown period not met"
        );

        creators[msg.sender].lastWithdrawalTime = block.timestamp;
        creatorBalance[msg.sender] = 0;

        payable(msg.sender).sendValue(amount);
        emit WithdrawnTips(msg.sender, amount);
    }

    // Tipping functions
    function tipCreator(
        address creator,
        string calldata message
    ) external payable nonReentrant whenNotPaused withinRateLimit(msg.value) {
        require(msg.value > 0, "Tip amount must be greater than 0");
        require(msg.value <= maxTipAmount, "Tip amount too large");
        require(creators[creator].isRegistered, "Creator not registered");
        require(creator != msg.sender, "Cannot tip yourself");

        creatorBalance[creator] += msg.value;
        creators[creator].totalTipsReceived += msg.value;

        emit TipSent(msg.sender, creator, msg.value, message);
    }

    function batchTipCreators(
        address[] calldata _creators,
        uint256[] calldata _amounts
    ) external payable nonReentrant whenNotPaused {
        require(_creators.length == _amounts.length, "Arrays length mismatch");
        require(_creators.length > 0, "Empty arrays");
        
        uint256 totalAmount;
        for(uint256 i = 0; i < _amounts.length; i++) {
            totalAmount += _amounts[i];
        }
        require(msg.value == totalAmount, "Incorrect total amount");

        for(uint256 i = 0; i < _creators.length; i++) {
            require(creators[_creators[i]].isRegistered, "Creator not registered");
            require(_creators[i] != msg.sender, "Cannot tip yourself");
            require(_amounts[i] <= maxTipAmount, "Tip amount too large");

            creatorBalance[_creators[i]] += _amounts[i];
            creators[_creators[i]].totalTipsReceived += _amounts[i];
        }

        emit BatchTipSent(msg.sender, _creators, _amounts);
    }

    // View functions
    function getCreatorDetails(address creator) external view returns (
        string memory name,
        bool isRegistered,
        bool isVerified,
        uint256 totalTipsReceived,
        uint256 currentBalance,
        uint256 registrationTime
    ) {
        Creator memory c = creators[creator];
        return (
            c.name,
            c.isRegistered,
            c.isVerified,
            c.totalTipsReceived,
            creatorBalance[creator],
            c.registrationTime
        );
    }

    function getRateLimit(address user) external view returns (
        uint256 currentUsage,
        uint256 maxAmount,
        uint256 resetTime
    ) {
        RateLimit memory limit = rateLimits[user];
        uint256 resetTimeStamp = limit.lastResetTime + RATE_LIMIT_PERIOD;
        if (block.timestamp >= resetTimeStamp) {
            return (0, maxTipAmount, block.timestamp + RATE_LIMIT_PERIOD);
        }
        return (limit.currentUsage, maxTipAmount, resetTimeStamp);
    }
}