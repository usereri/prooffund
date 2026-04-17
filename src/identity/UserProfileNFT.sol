// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title UserProfileNFT
 * @notice ERC721 for on-chain user identity with trust scores and respect points
 */
contract UserProfileNFT is ERC721URIStorage, Ownable {
    uint256 private _tokenIdCounter;

    struct Profile {
        uint256 trustScore;
        uint256 totalRespect;
        uint256 memberSince;
        string username;
    }

    mapping(uint256 => Profile) public profiles;
    mapping(address => uint256) public walletToTokenId;

    event ProfileMinted(address indexed to, uint256 tokenId, string username);
    event TrustScoreUpdated(uint256 indexed tokenId, uint256 newScore);
    event RespectAdded(uint256 indexed tokenId, uint256 respect, uint256 newTotal);

    constructor() ERC721("ProofFund Profile", "PFP") Ownable(msg.sender) {}

    /**
     * @notice Mint a new profile NFT for a user
     * @param to The address receiving the NFT
     * @param username The username for this profile
     * @return tokenId The ID of the newly minted token
     */
    function mintProfile(address to, string memory username) external onlyOwner returns (uint256 tokenId) {
        require(walletToTokenId[to] == 0, "Profile already exists for this wallet");

        tokenId = _tokenIdCounter++;
        _safeMint(to, tokenId);
        walletToTokenId[to] = tokenId;

        profiles[tokenId] = Profile({
            trustScore: 0,
            totalRespect: 0,
            memberSince: block.timestamp,
            username: username
        });

        emit ProfileMinted(to, tokenId, username);
    }

    /**
     * @notice Update the trust score of a profile
     * @param tokenId The token ID of the profile
     * @param newScore The new trust score value
     */
    function updateTrustScore(uint256 tokenId, uint256 newScore) external onlyOwner {
        require(ownerOf(tokenId) != address(0), "Profile does not exist");
        profiles[tokenId].trustScore = newScore;
        emit TrustScoreUpdated(tokenId, newScore);
    }

    /**
     * @notice Add respect points to a profile
     * @param tokenId The token ID of the profile
     * @param respect The amount of respect to add
     */
    function addRespect(uint256 tokenId, uint256 respect) external onlyOwner {
        require(ownerOf(tokenId) != address(0), "Profile does not exist");
        profiles[tokenId].totalRespect += respect;
        emit RespectAdded(tokenId, respect, profiles[tokenId].totalRespect);
    }

    /**
     * @notice Get the full profile data for a token
     * @param tokenId The token ID
     * @return Profile struct with all data
     */
    function getProfile(uint256 tokenId) external view returns (Profile memory) {
        require(ownerOf(tokenId) != address(0), "Profile does not exist");
        return profiles[tokenId];
    }

    /**
     * @notice Get the token ID associated with a wallet address
     * @param wallet The wallet address
     * @return tokenId or 0 if no profile exists
     */
    function getTokenIdByWallet(address wallet) external view returns (uint256) {
        return walletToTokenId[wallet];
    }

    /**
     * @notice Get total supply of profile NFTs
     * @return The total number of minted profiles
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter;
    }

    /**
     * @notice Check if a wallet has a profile
     * @param wallet The wallet address to check
     * @return True if profile exists
     */
    function hasProfile(address wallet) external view returns (bool) {
        return walletToTokenId[wallet] != 0;
    }
}