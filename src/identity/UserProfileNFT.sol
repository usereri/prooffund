// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UserProfileNFT is ERC721URIStorage, Ownable {
    uint256 private _tokenIdCounter = 1;

    struct Profile {
        string username;
        uint256 memberSince;
    }

    struct Badge {
        uint256 communityId;
        uint256 awardedAt;
        string reason;
    }

    mapping(uint256 tokenId => Profile) public profiles;
    mapping(address wallet => uint256 tokenId) public walletToTokenId;

    mapping(address wallet => mapping(uint256 communityId => uint256)) public communityReputation;

    mapping(address wallet => Badge[]) private _badges;

    mapping(address => bool) public authorizedWriters;

    event ProfileMinted(address indexed wallet, uint256 indexed tokenId, string username);
    event ReputationAdded(address indexed wallet, uint256 indexed communityId, uint256 amount, uint256 newTotal);
    event BadgeAwarded(address indexed wallet, uint256 indexed communityId, string reason);
    event WriterAuthorized(address indexed writer);
    event WriterRevoked(address indexed writer);

    modifier onlyAuthorizedWriter() {
        require(authorizedWriters[msg.sender] || msg.sender == owner(), "Not authorized writer");
        _;
    }

    constructor() ERC721("CoworkID", "CWID") Ownable(msg.sender) {}

    function authorizeWriter(address writer) external onlyOwner {
        authorizedWriters[writer] = true;
        emit WriterAuthorized(writer);
    }

    function revokeWriter(address writer) external onlyOwner {
        authorizedWriters[writer] = false;
        emit WriterRevoked(writer);
    }

    function mintProfile(address to, string calldata username) external onlyOwner returns (uint256 tokenId) {
        require(!hasProfile(to), "Profile already exists");

        tokenId = _tokenIdCounter++;
        _safeMint(to, tokenId);
        walletToTokenId[to] = tokenId;

        profiles[tokenId] = Profile({username: username, memberSince: block.timestamp});

        emit ProfileMinted(to, tokenId, username);
    }

    function hasProfile(address wallet) public view returns (bool) {
        return walletToTokenId[wallet] != 0;
    }

    function getProfile(uint256 tokenId) external view returns (Profile memory) {
        return profiles[tokenId];
    }

    function getTokenIdByWallet(address wallet) external view returns (uint256) {
        return walletToTokenId[wallet];
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter - 1;
    }

    function addReputation(address wallet, uint256 communityId, uint256 amount) external onlyAuthorizedWriter {
        communityReputation[wallet][communityId] += amount;
        emit ReputationAdded(wallet, communityId, amount, communityReputation[wallet][communityId]);
    }

    function getReputation(address wallet, uint256 communityId) external view returns (uint256) {
        return communityReputation[wallet][communityId];
    }

    function awardBadge(address wallet, uint256 communityId, string calldata reason) external onlyAuthorizedWriter {
        _badges[wallet].push(Badge({communityId: communityId, awardedAt: block.timestamp, reason: reason}));
        emit BadgeAwarded(wallet, communityId, reason);
    }

    function getBadges(address wallet) external view returns (Badge[] memory) {
        return _badges[wallet];
    }

    function getBadgeCount(address wallet) external view returns (uint256) {
        return _badges[wallet].length;
    }
}
