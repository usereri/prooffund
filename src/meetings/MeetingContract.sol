// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title MeetingContract
 * @notice Per-meeting deployed contract for attendance tracking and check-in
 * @dev Meeting owner deploys a new contract instance per meeting
 */
contract MeetingContract is Ownable, IERC721Receiver {
    uint256 public immutable meetingId;
    uint256 public immutable startTime;
    uint256 public immutable endTime;
    bytes32 public immutable qrHash;
    string public title;

    // Registry address for accessing other contracts
    address public immutable registry;

    // Track checked-in attendees
    mapping(address => bool) public hasCheckedIn;
    address[] public checkedInAttendees;

    // Factory tracking
    address public immutable factory;
    bool public isFinalized = false;

    event CheckedIn(address indexed attendee);
    event MeetingFinalized(uint256 totalAttendees);

    constructor(
        address _registry,
        uint256 _meetingId,
        string memory _title,
        uint256 _startTime,
        uint256 _endTime,
        bytes32 _qrHash,
        address _factory
    ) Ownable(msg.sender) {
        require(_startTime < _endTime, "Invalid time window");
        require(_endTime > block.timestamp, "End time must be in future");

        registry = _registry;
        meetingId = _meetingId;
        title = _title;
        startTime = _startTime;
        endTime = _endTime;
        qrHash = _qrHash;
        factory = _factory;
    }

    /**
     * @notice Check in to the meeting during the active window
     * @param attendee Address of the attendee
     */
    function checkIn(address attendee) external {
        require(msg.sender == attendee || msg.sender == owner(), "Not authorized");
        require(block.timestamp >= startTime, "Meeting has not started");
        require(block.timestamp <= endTime, "Meeting window has closed");
        require(!hasCheckedIn[attendee], "Already checked in");
        require(!isFinalized, "Meeting already finalized");

        hasCheckedIn[attendee] = true;
        checkedInAttendees.push(attendee);

        emit CheckedIn(attendee);
    }

    /**
     * @notice Get the count of checked-in attendees
     * @return Number of attendees
     */
    function getCheckedInCount() external view returns (uint256) {
        return checkedInAttendees.length;
    }

    /**
     * @notice Check if a specific address has checked in
     * @param attendee Address to check
     * @return True if checked in
     */
    function hasAttended(address attendee) external view returns (bool) {
        return hasCheckedIn[attendee];
    }

    /**
     * @notice Get the list of all checked-in attendees
     * @return Array of attendee addresses
     */
    function getAttendees() external view returns (address[] memory) {
        return checkedInAttendees;
    }

    /**
     * @notice Finalize the meeting and mint attendance NFTs for all attendees
     * @dev Can only be called after endTime. Calls MeetingAttendanceNFT.mintPresence() for each attendee.
     */
    function finalize() external onlyOwner {
        require(!isFinalized, "Already finalized");
        require(block.timestamp > endTime, "Meeting still active");

        isFinalized = true;
        address nftContract = IMeetingContractRegistry(registry).meetingAttendanceNFT();

        for (uint256 i = 0; i < checkedInAttendees.length; i++) {
            // Generate metadata URI for this attendance
            string memory metadataURI = _generateMetadataURI(checkedInAttendees[i], i);

            IMeetingNFT(nftContract).mintPresence(
                checkedInAttendees[i],
                meetingId,
                metadataURI
            );
        }

        emit MeetingFinalized(checkedInAttendees.length);
    }

    /**
     * @notice Generate metadata URI for an attendance NFT
     * @dev In production, this should point to IPFS. For demo, using a placeholder format.
     */
    function _generateMetadataURI(address attendee, uint256 index) internal view returns (string memory) {
        // Format: https://api.prooffund.com/meeting-metadata/{meetingId}/{attendeeIndex}
        // For now, return a placeholder that the frontend can resolve
        return string(abi.encodePacked(
            "https://api.prooffund.com/meeting-metadata/",
            Strings.toString(meetingId),
            "/",
            Strings.toString(index)
        ));
    }

    /**
     * @dev Required for receiving ERC721 tokens (when minting)
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

// Minimal interfaces for external contract calls
interface IMeetingContractRegistry {
    function meetingAttendanceNFT() external view returns (address);
}

interface IMeetingNFT {
    function mintPresence(
        address attendee,
        uint256 meetingId,
        string memory metadataURI
    ) external returns (uint256 tokenId);
}

// String utility for concatenating metadata URIs
library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
