// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MeetingAttendanceNFT
 * @notice ERC721 for meeting attendance collectibles - users collect meeting NFTs shown on their profile
 * @dev Single deployed contract that all MeetingContracts mint into via mintPresence()
 */
contract MeetingAttendanceNFT is ERC721URIStorage, Ownable {
    uint256 private _tokenIdCounter;

    // Track attendance tokens per user
    mapping(address => uint256[]) private _userTokens;
    // Track meeting attendance
    mapping(uint256 => uint256) public tokenToMeetingId;
    // Allowed minters (MeetingContracts registered via registry)
    mapping(address => bool) public authorizedMinters;

    event AttendanceMinted(address indexed attendee, uint256 tokenId, uint256 meetingId);
    event MinterAuthorized(address indexed minter);
    event MinterRevoked(address indexed minter);

    constructor() ERC721("ProofFund Attendance", "PFA") Ownable(msg.sender) {}

    /**
     * @notice Authorize a minter (MeetingContract) to mint attendance NFTs
     * @param minter The address to authorize
     */
    function authorizeMinter(address minter) external onlyOwner {
        authorizedMinters[minter] = true;
        emit MinterAuthorized(minter);
    }

    /**
     * @notice Revoke minter authorization
     * @param minter The address to revoke
     */
    function revokeMinter(address minter) external onlyOwner {
        authorizedMinters[minter] = false;
        emit MinterRevoked(minter);
    }

    /**
     * @notice Mint an attendance NFT for a participant
     * @param attendee The address receiving the attendance NFT
     * @param meetingId The ID of the meeting attended
     * @param metadataURI The IPFS URI with meeting metadata
     * @return tokenId The ID of the minted token
     */
    function mintPresence(
        address attendee,
        uint256 meetingId,
        string memory metadataURI
    ) external returns (uint256 tokenId) {
        require(authorizedMinters[msg.sender], "Not authorized to mint");
        require(attendee != address(0), "Invalid attendee address");

        tokenId = _tokenIdCounter++;
        _safeMint(attendee, tokenId);
        _setTokenURI(tokenId, metadataURI);

        tokenToMeetingId[tokenId] = meetingId;
        _userTokens[attendee].push(tokenId);

        emit AttendanceMinted(attendee, tokenId, meetingId);
    }

    /**
     * @notice Get all attendance tokens owned by a user
     * @param user The wallet address to query
     * @return Array of token IDs
     */
    function getAttendances(address user) external view returns (uint256[] memory) {
        return _userTokens[user];
    }

    /**
     * @notice Get the meeting ID for an attendance token
     * @param tokenId The token ID to query
     * @return The meeting ID
     */
    function getMeetingId(uint256 tokenId) external view returns (uint256) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        return tokenToMeetingId[tokenId];
    }

    /**
     * @notice Get total attendance count for a user
     * @param user The wallet address
     * @return The number of attendance NFTs
     */
    function getAttendanceCount(address user) external view returns (uint256) {
        return _userTokens[user].length;
    }

    /**
     * @notice Get total supply of attendance NFTs
     * @return The total number of minted attendance tokens
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter;
    }

}