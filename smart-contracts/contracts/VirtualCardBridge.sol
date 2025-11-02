// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title VirtualCardBridge
 * @dev Smart contract for Web3/Web2 bridge that accepts payments and triggers virtual card generation
 * Implements security best practices: multi-sig governance, reentrancy protection, access controls
 */
contract VirtualCardBridge is AccessControl, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    // Roles for multi-signature governance
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    
    // Payment configuration
    uint256 public minPaymentAmount = 0.0001 ether; // Minimum ETH payment ($0.25 - accessible for emergency use)
    uint256 public minSovrPaymentAmount = 1 * 10**18; // Minimum SOVR payment (1 SOVR - $1 USD)
    
    // Supported tokens
    IERC20 public immutable sovToken;
    
    // Nonce for replay protection
    mapping(address => uint256) public userNonces;
    
    // Transaction tracking
    mapping(bytes32 => bool) public processedTransactions;
    
    // Events for cross-domain communication
    event CardGenerationRequest(
        address indexed user,
        uint256 amount,
        bytes32 indexed txHash,
        uint256 timestamp,
        uint256 nonce,
        string currency
    );
    
    event CardGenerated(
        address indexed user,
        bytes32 indexed txHash,
        string cardId,
        uint256 timestamp
    );
    
    event MinimumAmountUpdated(uint256 oldAmount, uint256 newAmount);
    event FundsWithdrawn(address indexed to, uint256 amount);
    
    constructor(address _sovToken) {
        require(_sovToken != address(0), "Invalid SOVR token address");
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
        
        sovToken = IERC20(_sovToken);
    }
    
    /**
     * @dev Purchase virtual card with ETH payment
     * Emits CardGenerationRequest event for off-chain processing
     */
    function purchaseCard() external payable nonReentrant whenNotPaused {
        require(msg.value >= minPaymentAmount, "Payment below minimum threshold");
        
        uint256 nonce = userNonces[msg.sender];
        userNonces[msg.sender]++;
        
        bytes32 txHash = keccak256(
            abi.encodePacked(
                msg.sender,
                msg.value,
                nonce,
                block.timestamp,
                block.chainid
            )
        );
        
        require(!processedTransactions[txHash], "Transaction already processed");
        processedTransactions[txHash] = true;
        
        emit CardGenerationRequest(
            msg.sender,
            msg.value,
            txHash,
            block.timestamp,
            nonce,
            "ETH"
        );
    }

    /**
     * @dev Purchase virtual card with SOVR stablecoin payment
     * Emits CardGenerationRequest event for off-chain processing
     * @param amount Amount of SOVR tokens to pay (in wei units)
     */
    function purchaseCardWithSovr(uint256 amount) external nonReentrant whenNotPaused {
        require(amount >= minSovrPaymentAmount, "SOVR payment below minimum threshold");
        
        uint256 nonce = userNonces[msg.sender];
        userNonces[msg.sender]++;
        
        bytes32 txHash = keccak256(
            abi.encodePacked(
                msg.sender,
                amount,
                nonce,
                block.timestamp,
                block.chainid
            )
        );
        
        require(!processedTransactions[txHash], "Transaction already processed");
        processedTransactions[txHash] = true;
        
        // Transfer SOVR tokens to contract
        sovToken.safeTransferFrom(msg.sender, address(this), amount);
        
        emit CardGenerationRequest(
            msg.sender,
            amount,
            txHash,
            block.timestamp,
            nonce,
            "SOVR"
        );
    }
    
    /**
     * @dev Confirm card generation (called by operator after Stripe card created)
     * @param user User address
     * @param txHash Original transaction hash
     * @param cardId Stripe card ID
     */
    function confirmCardGeneration(
        address user,
        bytes32 txHash,
        string memory cardId
    ) external onlyRole(OPERATOR_ROLE) {
        require(processedTransactions[txHash], "Transaction not found");
        
        emit CardGenerated(user, txHash, cardId, block.timestamp);
    }
    
    /**
     * @dev Update minimum payment amounts (multi-sig admin only)
     * @param newMinEth New minimum ETH amount in wei
     * @param newMinSovr New minimum SOVR amount in wei
     */
    function updateMinimumAmounts(uint256 newMinEth, uint256 newMinSovr) external onlyRole(ADMIN_ROLE) {
        require(newMinEth > 0, "ETH amount must be greater than zero");
        require(newMinSovr > 0, "SOVR amount must be greater than zero");
        
        uint256 oldMinEth = minPaymentAmount;
        uint256 oldMinSovr = minSovrPaymentAmount;
        
        minPaymentAmount = newMinEth;
        minSovrPaymentAmount = newMinSovr;
        
        emit MinimumAmountUpdated(oldMinEth, newMinEth);
        // You might want to emit another event for SOVR amounts
    }
    
    /**
     * @dev Get SOVR token balance
     */
    function getSovrBalance() external view returns (uint256) {
        return sovToken.balanceOf(address(this));
    }
    
    /**
     * @dev Get both ETH and SOVR balances
     */
    function getBalances() external view returns (uint256 ethBalance, uint256 sovBalance) {
        return (address(this).balance, sovToken.balanceOf(address(this)));
    }
    
    /**
     * @dev Emergency pause (guardian role)
     */
    function pause() external onlyRole(GUARDIAN_ROLE) {
        _pause();
    }
    
    /**
     * @dev Resume operations (admin role)
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }
    
    /**
     * @dev Withdraw accumulated funds (admin role with multi-sig)
     * @param to Destination address
     * @param amount Amount to withdraw
     * @param currency Currency type: "ETH" or "SOVR"
     */
    function withdrawFunds(address payable to, uint256 amount, string memory currency) 
        external 
        onlyRole(ADMIN_ROLE) 
        nonReentrant 
    {
        require(to != address(0), "Invalid address");
        
        if (keccak256(bytes(currency)) == keccak256(bytes("ETH"))) {
            require(amount <= address(this).balance, "Insufficient ETH balance");
            (bool success, ) = to.call{value: amount}("");
            require(success, "ETH transfer failed");
        } else if (keccak256(bytes(currency)) == keccak256(bytes("SOVR"))) {
            uint256 sovBalance = sovToken.balanceOf(address(this));
            require(amount <= sovBalance, "Insufficient SOVR balance");
            sovToken.safeTransfer(to, amount);
        } else {
            revert("Unsupported currency");
        }
        
        emit FundsWithdrawn(to, amount);
    }
    
    /**
     * @dev Get user's current nonce
     * @param user User address
     */
    function getUserNonce(address user) external view returns (uint256) {
        return userNonces[user];
    }
    
    /**
     * @dev Get contract balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Check if transaction has been processed
     * @param txHash Transaction hash
     */
    function isProcessed(bytes32 txHash) external view returns (bool) {
        return processedTransactions[txHash];
    }
}
