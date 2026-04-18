// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IUserProfileNFT {
    function hasProfile(address wallet) external view returns (bool);

    function getReputation(
        address wallet,
        uint256 communityId
    ) external view returns (uint256);

    function addReputation(
        address wallet,
        uint256 communityId,
        uint256 amount
    ) external;

    function awardBadge(
        address wallet,
        uint256 communityId,
        string calldata reason
    ) external;
}

contract CommunityRegistry is Ownable {
    struct Community {
        uint256 id;
        string name;
        string location;
        address host;
        uint256 createdAt;
        bool active;
    }

    struct EventRecord {
        uint256 id;
        uint256 communityId;
        string name;
        uint256 startTime;
        uint256 endTime;
        bytes32 qrHash;
        uint256 reputationReward;
        uint256 minReputationRequired;
        address host;
        bool finalized;
        uint256 attendeeCount;
    }

    uint256 public constant MIN_COMMUNITY_STAKE = 0.01 ether;
    uint256 public constant MIN_ACTIVE_PERIOD = 30 days;

    address public userProfileNft;
    address public feeRecipient;

    uint256 private _communityIdCounter = 1;
    uint256 private _eventIdCounter = 1;

    mapping(uint256 communityId => uint256) public communityStake;
    mapping(uint256 communityId => uint256) public communityStakedAt;

    mapping(uint256 communityId => Community) public communities;
    mapping(uint256 eventId => EventRecord) public events;

    mapping(address wallet => bool) public isHost;

    mapping(uint256 communityId => address[]) private _communityMembers;
    mapping(uint256 communityId => mapping(address => bool)) public isMember;
    mapping(address => uint256[]) private _memberCommunities;
    mapping(address => uint256[]) private _hostedCommunities;

    mapping(uint256 communityId => uint256[]) private _communityEvents;
    mapping(uint256 eventId => address[]) private _eventAttendees;
    mapping(uint256 eventId => mapping(address => bool)) public hasAttended;

    mapping(uint256 communityId => address) public communityTopEarner;
    mapping(uint256 communityId => uint256) public communityTopScore;

    event CommunityCreated(
        uint256 indexed communityId,
        string name,
        address indexed host
    );
    event CommunityDeactivated(uint256 indexed communityId);
    event HostGranted(address indexed wallet);
    event HostRevoked(address indexed wallet);
    event MemberJoined(uint256 indexed communityId, address indexed member);
    event EventCreated(
        uint256 indexed eventId,
        uint256 indexed communityId,
        string name,
        bytes32 qrHash
    );
    event AttendanceRecorded(address indexed user, uint256 indexed eventId);
    event EventFinalized(uint256 indexed eventId, uint256 attendeeCount);
    event LeaderboardUpdated(
        uint256 indexed communityId,
        address indexed newTopEarner,
        uint256 score
    );
    event CommunityStaked(
        uint256 indexed communityId,
        address indexed host,
        uint256 amount
    );
    event StakeSlashed(uint256 indexed communityId, uint256 amount);
    event StakeWithdrawn(
        uint256 indexed communityId,
        address indexed host,
        uint256 amount
    );

    modifier onlyHost() {
        _onlyHost();
        _;
    }

    function _onlyHost() internal view {
        require(isHost[msg.sender] || msg.sender == owner(), "Not a host");
    }

    modifier onlyHostOf(uint256 communityId) {
        _onlyHostOf(communityId);
        _;
    }

    function _onlyHostOf(uint256 communityId) internal view {
        require(
            communities[communityId].host == msg.sender ||
                msg.sender == owner(),
            "Not community host"
        );
    }

    modifier communityExists(uint256 communityId) {
        _communityExists(communityId);
        _;
    }

    function _communityExists(uint256 communityId) internal view {
        require(
            communityId != 0 && communityId < _communityIdCounter,
            "Community does not exist"
        );
        require(communities[communityId].active, "Community is not active");
    }

    modifier eventExists(uint256 eventId) {
        _eventExists(eventId);
        _;
    }

    function _eventExists(uint256 eventId) internal view {
        require(
            eventId != 0 && eventId < _eventIdCounter,
            "Event does not exist"
        );
    }

    constructor(
        address _owner,
        address _userProfileNft,
        address _feeRecipient
    ) Ownable(_owner) {
        userProfileNft = _userProfileNft;
        feeRecipient = _feeRecipient;
    }

    function grantHost(address wallet) external onlyOwner {
        isHost[wallet] = true;
        emit HostGranted(wallet);
    }

    function revokeHost(address wallet) external onlyOwner {
        isHost[wallet] = false;
        emit HostRevoked(wallet);
    }

    function createCommunity(
        string calldata name,
        string calldata location
    ) external payable onlyHost returns (uint256 communityId) {
        require(msg.value >= MIN_COMMUNITY_STAKE, "Insufficient stake");
        communityId = _communityIdCounter++;
        communities[communityId] = Community({
            id: communityId,
            name: name,
            location: location,
            host: msg.sender,
            createdAt: block.timestamp,
            active: true
        });
        communityStake[communityId] = msg.value;
        communityStakedAt[communityId] = block.timestamp;
        _hostedCommunities[msg.sender].push(communityId);
        emit CommunityCreated(communityId, name, msg.sender);
        emit CommunityStaked(communityId, msg.sender, msg.value);
    }

    function deactivateCommunity(
        uint256 communityId
    ) external onlyHostOf(communityId) {
        communities[communityId].active = false;
        uint256 stake = communityStake[communityId];
        if (stake > 0 && block.timestamp < communityStakedAt[communityId] + MIN_ACTIVE_PERIOD) {
            communityStake[communityId] = 0;
            (bool ok,) = feeRecipient.call{value: stake}("");
            require(ok, "Slash transfer failed");
            emit StakeSlashed(communityId, stake);
        }
        emit CommunityDeactivated(communityId);
    }

    function withdrawStake(uint256 communityId) external {
        require(communities[communityId].host == msg.sender, "Not host");
        require(
            block.timestamp >= communityStakedAt[communityId] + MIN_ACTIVE_PERIOD,
            "Too early"
        );
        uint256 amount = communityStake[communityId];
        require(amount > 0, "Nothing to withdraw");
        communityStake[communityId] = 0;
        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "Withdraw transfer failed");
        emit StakeWithdrawn(communityId, msg.sender, amount);
    }

    function joinCommunity(
        uint256 communityId
    ) external communityExists(communityId) {
        require(
            IUserProfileNFT(userProfileNft).hasProfile(msg.sender),
            "Must have a profile first"
        );
        require(!isMember[communityId][msg.sender], "Already a member");

        isMember[communityId][msg.sender] = true;
        _communityMembers[communityId].push(msg.sender);
        _memberCommunities[msg.sender].push(communityId);

        emit MemberJoined(communityId, msg.sender);
    }

    function addMember(
        uint256 communityId,
        address member
    ) external onlyHostOf(communityId) communityExists(communityId) {
        require(
            IUserProfileNFT(userProfileNft).hasProfile(member),
            "Member must have a profile"
        );
        require(!isMember[communityId][member], "Already a member");

        isMember[communityId][member] = true;
        _communityMembers[communityId].push(member);
        _memberCommunities[member].push(communityId);

        emit MemberJoined(communityId, member);
    }

    function createEvent(
        uint256 communityId,
        string calldata name,
        uint256 startTime,
        uint256 endTime,
        bytes32 qrHash,
        uint256 reputationReward,
        uint256 minReputationRequired
    )
        external
        onlyHostOf(communityId)
        communityExists(communityId)
        returns (uint256 eventId)
    {
        require(endTime > startTime, "End must be after start");

        eventId = _eventIdCounter++;
        events[eventId] = EventRecord({
            id: eventId,
            communityId: communityId,
            name: name,
            startTime: startTime,
            endTime: endTime,
            qrHash: qrHash,
            reputationReward: reputationReward,
            minReputationRequired: minReputationRequired,
            host: msg.sender,
            finalized: false,
            attendeeCount: 0
        });
        _communityEvents[communityId].push(eventId);

        emit EventCreated(eventId, communityId, name, qrHash);
    }

    function finalizeEvent(
        uint256 eventId,
        address[] calldata attendees
    ) external eventExists(eventId) {
        EventRecord storage ev = events[eventId];
        require(!ev.finalized, "Already finalized");
        require(block.timestamp > ev.endTime, "Event still active");
        require(
            ev.host == msg.sender || msg.sender == owner(),
            "Not event host"
        );

        uint256 communityId = ev.communityId;
        uint256 reputationReward = ev.reputationReward;

        for (uint256 i = 0; i < attendees.length; i++) {
            address attendee = attendees[i];
            require(!hasAttended[eventId][attendee], "Duplicate attendee");

            hasAttended[eventId][attendee] = true;
            _eventAttendees[eventId].push(attendee);

            emit AttendanceRecorded(attendee, eventId);

            if (reputationReward > 0) {
                IUserProfileNFT(userProfileNft).addReputation(
                    attendee,
                    communityId,
                    reputationReward
                );
                uint256 newScore = IUserProfileNFT(userProfileNft)
                    .getReputation(attendee, communityId);
                _checkAndUpdateLeaderboard(attendee, communityId, newScore);
            }
        }

        ev.finalized = true;
        ev.attendeeCount = attendees.length;

        emit EventFinalized(eventId, attendees.length);
    }

    function _checkAndUpdateLeaderboard(
        address wallet,
        uint256 communityId,
        uint256 newScore
    ) internal {
        if (newScore > communityTopScore[communityId]) {
            communityTopEarner[communityId] = wallet;
            communityTopScore[communityId] = newScore;
            emit LeaderboardUpdated(communityId, wallet, newScore);
            IUserProfileNFT(userProfileNft).awardBadge(
                wallet,
                communityId,
                "Top community earner"
            );
        }
    }

    function isEligibleForEvent(
        address wallet,
        uint256 eventId
    ) external view returns (bool) {
        EventRecord storage ev = events[eventId];
        if (ev.minReputationRequired == 0) return true;
        return
            IUserProfileNFT(userProfileNft).getReputation(
                wallet,
                ev.communityId
            ) >= ev.minReputationRequired;
    }

    function getCommunity(
        uint256 communityId
    ) external view returns (Community memory) {
        return communities[communityId];
    }

    function getEvent(
        uint256 eventId
    ) external view returns (EventRecord memory) {
        return events[eventId];
    }

    function getEventAttendees(
        uint256 eventId
    ) external view returns (address[] memory) {
        return _eventAttendees[eventId];
    }

    function getCommunityEvents(
        uint256 communityId
    ) external view returns (uint256[] memory) {
        return _communityEvents[communityId];
    }

    function getCommunityMembers(
        uint256 communityId
    ) external view returns (address[] memory) {
        return _communityMembers[communityId];
    }

    function getMemberCommunities(
        address member
    ) external view returns (uint256[] memory) {
        return _memberCommunities[member];
    }

    function getHostedCommunities(
        address host
    ) external view returns (uint256[] memory) {
        return _hostedCommunities[host];
    }

    function getCommunityCount() external view returns (uint256) {
        return _communityIdCounter - 1;
    }

    function getEventCount() external view returns (uint256) {
        return _eventIdCounter - 1;
    }
}
