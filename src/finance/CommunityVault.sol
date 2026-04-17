// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title CommunityVault
 * @notice Holds 30% of monthly treasury for community governance
 * @dev Community can request funds and vote on allocations
 */
contract CommunityVault is Ownable, ReentrancyGuard {
    uint256 public constant QUORUM_PERCENTAGE = 51; // 51% of NFT holders must vote
    uint256 public constant SUPPORT_THRESHOLD = 60; // 60% support required

    struct Request {
        address payable to;
        uint256 amount;
        string reason;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        uint256 createdAt;
    }

    // Track all fund requests
    Request[] public requests;
    // Track if a wallet has voted on a request
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    // Track total votes cast (for quorum calculation)
    mapping(uint256 => uint256) public totalVotesCast;

    // Contract registry for accessing UserProfileNFT
    address public registry;

    event FundsReceived(address indexed from, uint256 amount);
    event FundsRequested(uint256 indexed requestId, address indexed to, uint256 amount, string reason);
    event Voted(uint256 indexed requestId, address indexed voter, bool support);
    event RequestExecuted(uint256 indexed requestId, address indexed to, uint256 amount);

    constructor(address _registry) Ownable(msg.sender) {
        registry = _registry;
    }

    /**
     * @notice Receive funds from TreasuryContract
     */
    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }

    /**
     * @notice Get the total balance in the vault
     * @return Current vault balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Get total number of fund requests
     * @return Count of all requests
     */
    function getRequestCount() external view returns (uint256) {
        return requests.length;
    }

    /**
     * @notice Request funds from the community vault
     * @param to Address to receive the funds
     * @param amount Amount of ETH requested
     * @param reason Reason/description for the request
     * @return requestId The ID of the newly created request
     */
    function requestFunds(
        address payable to,
        uint256 amount,
        string calldata reason
    ) external nonReentrant returns (uint256 requestId) {
        require(amount > 0, "Amount must be positive");
        require(amount <= address(this).balance, "Insufficient vault balance");

        requestId = requests.length;
        requests.push(Request({
            to: to,
            amount: amount,
            reason: reason,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            createdAt: block.timestamp
        }));

        emit FundsRequested(requestId, to, amount, reason);
    }

    /**
     * @notice Vote on a fund request
     * @param requestId The request to vote on
     * @param support True to support, false to oppose
     */
    function vote(uint256 requestId, bool support) external {
        require(requestId < requests.length, "Request does not exist");
        Request storage request = requests[requestId];
        require(!request.executed, "Request already executed");
        require(!hasVoted[requestId][msg.sender], "Already voted on this request");

        // Verify voter has a ProfileNFT
        uint256 voterTokenId = IVaultProfileNFT(IVaultRegistry(registry).userProfileNFT()).getTokenIdByWallet(msg.sender);
        require(voterTokenId != 0, "Must have a ProfileNFT to vote");

        hasVoted[requestId][msg.sender] = true;
        totalVotesCast[requestId]++;

        if (support) {
            request.votesFor++;
        } else {
            request.votesAgainst++;
        }

        emit Voted(requestId, msg.sender, support);
    }

    /**
     * @notice Execute a fund request if quorum and threshold are met
     * @param requestId The request to execute
     */
    function executeRequest(uint256 requestId) external nonReentrant {
        require(requestId < requests.length, "Request does not exist");
        Request storage request = requests[requestId];
        require(!request.executed, "Request already executed");

        uint256 totalSupply = IVaultProfileNFT(IVaultRegistry(registry).userProfileNFT()).totalSupply();
        require(totalSupply > 0, "No profile NFTs exist");

        // Calculate quorum percentage
        uint256 quorumPercentage = (totalVotesCast[requestId] * 100) / totalSupply;
        require(quorumPercentage >= QUORUM_PERCENTAGE, "Quorum not reached");

        // Calculate support percentage
        uint256 totalCast = request.votesFor + request.votesAgainst;
        require(totalCast > 0, "No votes cast");
        uint256 supportPercentage = (request.votesFor * 100) / totalCast;
        require(supportPercentage >= SUPPORT_THRESHOLD, "Insufficient support");

        request.executed = true;
        request.to.transfer(request.amount);

        emit RequestExecuted(requestId, request.to, request.amount);
    }

    /**
     * @notice Get request details
     * @param requestId The request ID
     * @return Full Request struct
     */
    function getRequest(uint256 requestId) external view returns (Request memory) {
        require(requestId < requests.length, "Request does not exist");
        return requests[requestId];
    }
}

// Minimal interfaces
interface IVaultRegistry {
    function userProfileNFT() external view returns (address);
}

interface IVaultProfileNFT {
    function totalSupply() external view returns (uint256);
    function getTokenIdByWallet(address wallet) external view returns (uint256);
}
