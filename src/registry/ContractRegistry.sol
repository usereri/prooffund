// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ContractRegistry
 * @notice Central registry for all contract addresses in the ecosystem
 * @dev Single deployed registry that all contracts reference
 */
contract ContractRegistry is Ownable {
    address public userProfileNFT;
    address public meetingAttendanceNFT;
    address public treasuryContract;
    address public communityVault;

    // Whitelist of valid MeetingContracts
    mapping(address => bool) public validMeetingContracts;
    address[] public meetingContractList;

    // Factory address (can deploy meeting contracts)
    address public meetingFactory;

    event ContractRegistered(string name, address indexed addr);
    event MeetingContractAdded(address indexed meetingAddress);
    event MeetingContractRemoved(address indexed meetingAddress);
    event FactoryUpdated(address indexed newFactory);

    constructor(address _owner) Ownable(_owner) {}

    /**
     * @notice Set the UserProfileNFT contract address
     * @param addr The contract address
     */
    function setUserProfileNFT(address addr) external onlyOwner {
        userProfileNFT = addr;
        emit ContractRegistered("UserProfileNFT", addr);
    }

    /**
     * @notice Set the MeetingAttendanceNFT contract address
     * @param addr The contract address
     */
    function setMeetingAttendanceNFT(address addr) external onlyOwner {
        meetingAttendanceNFT = addr;
        emit ContractRegistered("MeetingAttendanceNFT", addr);
    }

    /**
     * @notice Set the TreasuryContract address
     * @param addr The contract address
     */
    function setTreasuryContract(address addr) external onlyOwner {
        treasuryContract = addr;
        emit ContractRegistered("TreasuryContract", addr);
    }

    /**
     * @notice Set the CommunityVault address
     * @param addr The contract address
     */
    function setCommunityVault(address addr) external onlyOwner {
        communityVault = addr;
        emit ContractRegistered("CommunityVault", addr);
    }

    /**
     * @notice Set the meeting factory address
     * @param addr The factory contract address
     */
    function setMeetingFactory(address addr) external onlyOwner {
        meetingFactory = addr;
        emit FactoryUpdated(addr);
    }

    /**
     * @notice Add a valid meeting contract (called by factory or owner)
     * @param meetingAddress The meeting contract address
     */
    function addMeetingContract(address meetingAddress) external {
        require(msg.sender == meetingFactory || msg.sender == owner(), "Not authorized");
        require(meetingAddress != address(0), "Invalid address");

        if (!validMeetingContracts[meetingAddress]) {
            validMeetingContracts[meetingAddress] = true;
            meetingContractList.push(meetingAddress);
            emit MeetingContractAdded(meetingAddress);

            // Also authorize the meeting contract to mint attendance NFTs
            if (meetingAttendanceNFT != address(0)) {
                IMeetingAttendanceNFT(meetingAttendanceNFT).authorizeMinter(meetingAddress);
            }
        }
    }

    /**
     * @notice Remove a meeting contract from validity (only owner)
     * @param meetingAddress The meeting contract to remove
     */
    function removeMeetingContract(address meetingAddress) external onlyOwner {
        require(validMeetingContracts[meetingAddress], "Not a valid meeting contract");
        validMeetingContracts[meetingAddress] = false;
        emit MeetingContractRemoved(meetingAddress);
    }

    /**
     * @notice Check if a meeting contract is valid
     * @param meetingAddress The address to check
     * @return True if valid
     */
    function isMeetingValid(address meetingAddress) external view returns (bool) {
        return validMeetingContracts[meetingAddress];
    }

    /**
     * @notice Get the total count of registered meeting contracts
     * @return Number of meeting contracts
     */
    function getMeetingContractCount() external view returns (uint256) {
        return meetingContractList.length;
    }

    /**
     * @notice Get a meeting contract by index
     * @param index The index in the list
     * @return The meeting contract address
     */
    function getMeetingContract(uint256 index) external view returns (address) {
        require(index < meetingContractList.length, "Index out of bounds");
        return meetingContractList[index];
    }

    /**
     * @notice Get all registered meeting contracts
     * @return Array of all meeting contract addresses
     */
    function getAllMeetingContracts() external view returns (address[] memory) {
        return meetingContractList;
    }
}

// Minimal interface for interacting with MeetingAttendanceNFT
interface IMeetingAttendanceNFT {
    function authorizeMinter(address minter) external;
}