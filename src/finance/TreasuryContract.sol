// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title TreasuryContract
 * @notice Core governance for monthly payouts with vault split
 * @dev AI proposes member of month → community votes → 70% to winner, 30% to vault
 */
contract TreasuryContract is Ownable, ReentrancyGuard {
    uint256 public constant WINNER_PERCENTAGE = 70;  // 70% to monthly winner
    uint256 public constant VAULT_PERCENTAGE = 30;    // 30% to CommunityVault
    uint256 public constant PASS_THRESHOLD = 51;      // 51% support to pass
    uint256 public constant MAX_ROUNDS = 3;           // Max voting rounds before AI auto-executes

    struct Proposal {
        address payable nominee;
        uint256 amount;
        uint256 votesFor;
        uint256 votesAgainst;
        uint8 round;
        bool executed;
        bool aiAutoExecute;
        uint256 createdAt;
    }

    // Contract registry
    address public immutable registry;

    // Proposals
    Proposal[] public proposals;

    // Voting tracking
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Emergency requests
    struct EmergencyRequest {
        address payable to;
        uint256 amount;
        string reason;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        uint256 createdAt;
    }
    EmergencyRequest[] public emergencyRequests;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnEmergency;

    event ProposalCreated(uint256 indexed proposalId, address indexed nominee, uint256 amount);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, uint256 amountToWinner, uint256 amountToVault);
    event ProposalFailed(uint256 indexed proposalId, uint8 round);
    event AIAutoExecuted(uint256 indexed proposalId, uint256 amount);
    event EmergencyRequested(uint256 indexed requestId, address indexed to, uint256 amount, string reason);
    event EmergencyVoted(uint256 indexed requestId, address indexed voter, bool support);
    event EmergencyExecuted(uint256 indexed requestId);

    // Events for AI suggestion
    event SuggestionCreated(uint256 indexed proposalId, string reasoning);

    constructor(address _registry) Ownable(msg.sender) {
        registry = _registry;
    }

    /**
     * @notice Get total number of proposals
     * @return Count of all proposals
     */
    function getProposalCount() external view returns (uint256) {
        return proposals.length;
    }

    /**
     * @notice Get total number of emergency requests
     * @return Count of all emergency requests
     */
    function getEmergencyRequestCount() external view returns (uint256) {
        return emergencyRequests.length;
    }

    /**
     * @notice Create a new payout proposal (called by AI or anyone)
     * @param nominee Address to receive the payout
     * @param amount Amount of ETH to distribute
     */
    function proposePayout(address payable nominee, uint256 amount) public returns (uint256 proposalId) {
        require(amount > 0, "Amount must be positive");
        require(amount <= address(this).balance, "Insufficient treasury balance");

        proposalId = proposals.length;
        proposals.push(Proposal({
            nominee: nominee,
            amount: amount,
            votesFor: 0,
            votesAgainst: 0,
            round: 1,
            executed: false,
            aiAutoExecute: false,
            createdAt: block.timestamp
        }));

        emit ProposalCreated(proposalId, nominee, amount);
    }

    /**
     * @notice Create a proposal with AI reasoning (for transparency)
     * @param nominee Address to receive the payout
     * @param amount Amount of ETH to distribute
     * @param reasoning AI's reasoning for this suggestion
     */
    function proposeWithReasoning(
        address payable nominee,
        uint256 amount,
        string calldata reasoning
    ) external returns (uint256 proposalId) {
        proposalId = proposePayout(nominee, amount);
        emit SuggestionCreated(proposalId, reasoning);
    }

    /**
     * @notice Vote on a proposal
     * @param proposalId The proposal to vote on
     * @param support True to support, false to oppose
     */
    function vote(uint256 proposalId, bool support) external {
        require(proposalId < proposals.length, "Proposal does not exist");
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal already executed");
        require(!hasVoted[proposalId][msg.sender], "Already voted on this proposal");

        // Verify voter has a ProfileNFT
        address profileNFT = ITreasuryContractRegistry(registry).userProfileNFT();
        uint256 voterTokenId = ITreasuryProfileNFT(profileNFT).getTokenIdByWallet(msg.sender);
        require(voterTokenId != 0, "Must have a ProfileNFT to vote");

        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit Voted(proposalId, msg.sender, support);
    }

    /**
     * @notice Execute a proposal if passed
     * @param proposalId The proposal to execute
     */
    function executeProposal(uint256 proposalId) external nonReentrant {
        require(proposalId < proposals.length, "Proposal does not exist");
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes > 0, "No votes cast");

        uint256 supportPercentage = (proposal.votesFor * 100) / totalVotes;
        require(supportPercentage >= PASS_THRESHOLD, "Proposal did not pass");

        proposal.executed = true;

        // Calculate amounts
        uint256 amountToWinner = (proposal.amount * WINNER_PERCENTAGE) / 100;
        uint256 amountToVault = (proposal.amount * VAULT_PERCENTAGE) / 100;

        // Send to winner
        proposal.nominee.transfer(amountToWinner);

        // Send 30% to CommunityVault
        address vaultAddress = ITreasuryContractRegistry(registry).communityVault();
        (bool success, ) = vaultAddress.call{value: amountToVault}("");
        require(success, "Transfer to vault failed");

        emit ProposalExecuted(proposalId, amountToWinner, amountToVault);
    }

    /**
     * @notice Record a failed proposal round and check if max rounds reached
     * @param proposalId The proposal that failed
     * @return shouldAutoExecute True if AI auto-execute should happen
     */
    function recordFailedVote(uint256 proposalId) external returns (bool shouldAutoExecute) {
        require(proposalId < proposals.length, "Proposal does not exist");
        Proposal storage proposal = proposals[proposalId];

        proposal.round++;
        emit ProposalFailed(proposalId, proposal.round);

        if (proposal.round > MAX_ROUNDS && !proposal.executed) {
            proposal.aiAutoExecute = true;
            return true;
        }
        return false;
    }

    /**
     * @notice Auto-execute a proposal after 3 failed voting rounds
     * @param proposalId The proposal to auto-execute
     */
    function aiAutoExecute(uint256 proposalId) external nonReentrant {
        require(proposalId < proposals.length, "Proposal does not exist");
        Proposal storage proposal = proposals[proposalId];
        require(proposal.aiAutoExecute, "Not eligible for auto-execute");
        require(!proposal.executed, "Already executed");
        require(proposal.round > MAX_ROUNDS, "Max rounds not reached");

        proposal.executed = true;

        // Full amount goes to winner (AI suggestion auto-passes after 3 fails)
        proposal.nominee.transfer(proposal.amount);

        emit AIAutoExecuted(proposalId, proposal.amount);
    }

    /**
     * @notice Create an emergency fund request (higher threshold)
     * @param to Address to receive the funds
     * @param amount Amount requested
     * @param reason Reason for the request
     */
    function emergencyRequest(
        address payable to,
        uint256 amount,
        string calldata reason
    ) external returns (uint256 requestId) {
        require(amount > 0, "Amount must be positive");
        require(amount <= address(this).balance, "Insufficient treasury balance");

        requestId = emergencyRequests.length;
        emergencyRequests.push(EmergencyRequest({
            to: to,
            amount: amount,
            reason: reason,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            createdAt: block.timestamp
        }));

        emit EmergencyRequested(requestId, to, amount, reason);
    }

    /**
     * @notice Vote on an emergency request
     * @param requestId The request to vote on
     * @param support True to support, false to oppose
     */
    function voteOnEmergency(uint256 requestId, bool support) external {
        require(requestId < emergencyRequests.length, "Request does not exist");
        EmergencyRequest storage request = emergencyRequests[requestId];
        require(!request.executed, "Request already executed");
        require(!hasVotedOnEmergency[requestId][msg.sender], "Already voted");

        // Verify voter has a ProfileNFT
        address profileNFT = ITreasuryContractRegistry(registry).userProfileNFT();
        uint256 voterTokenId = ITreasuryProfileNFT(profileNFT).getTokenIdByWallet(msg.sender);
        require(voterTokenId != 0, "Must have a ProfileNFT to vote");

        hasVotedOnEmergency[requestId][msg.sender] = true;

        if (support) {
            request.votesFor++;
        } else {
            request.votesAgainst++;
        }

        emit EmergencyVoted(requestId, msg.sender, support);
    }

    /**
     * @notice Execute an emergency request (requires 66% support)
     * @param requestId The request to execute
     */
    function executeEmergencyRequest(uint256 requestId) external nonReentrant {
        require(requestId < emergencyRequests.length, "Request does not exist");
        EmergencyRequest storage request = emergencyRequests[requestId];
        require(!request.executed, "Request already executed");

        uint256 totalVotes = request.votesFor + request.votesAgainst;
        require(totalVotes > 0, "No votes cast");

        uint256 supportPercentage = (request.votesFor * 100) / totalVotes;
        require(supportPercentage >= 66, "Insufficient support (66% required)");

        request.executed = true;
        request.to.transfer(request.amount);

        emit EmergencyExecuted(requestId);
    }

    /**
     * @notice Get the treasury balance
     * @return Current treasury balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Get proposal details
     * @param proposalId The proposal ID
     * @return Full Proposal struct
     */
    function getProposal(uint256 proposalId) external view returns (Proposal memory) {
        require(proposalId < proposals.length, "Proposal does not exist");
        return proposals[proposalId];
    }

    /**
     * @notice Get emergency request details
     * @param requestId The request ID
     * @return Full EmergencyRequest struct
     */
    function getEmergencyRequest(uint256 requestId) external view returns (EmergencyRequest memory) {
        require(requestId < emergencyRequests.length, "Request does not exist");
        return emergencyRequests[requestId];
    }
}

// Minimal interfaces
interface ITreasuryContractRegistry {
    function userProfileNFT() external view returns (address);
    function communityVault() external view returns (address);
}

interface ITreasuryProfileNFT {
    function getTokenIdByWallet(address wallet) external view returns (uint256);
}