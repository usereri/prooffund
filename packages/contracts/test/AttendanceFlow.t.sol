// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {UserProfileNFT} from "../src/identity/UserProfileNFT.sol";
import {CommunityRegistry} from "../src/registry/CommunityRegistry.sol";

contract AttendanceFlowTest is Test {
    UserProfileNFT nft;
    CommunityRegistry registry;

    address deployer = address(this);
    address host = makeAddr("host");
    address user = makeAddr("user");
    address feeRecipient = makeAddr("feeRecipient");

    uint256 constant REP_REWARD = 100;
    uint256 constant START_OFFSET = 1 hours;
    uint256 constant DURATION = 2 hours;
    uint256 constant STAKE = 0.01 ether;

    event AttendanceRecorded(address indexed user, uint256 indexed eventId);
    event LeaderboardUpdated(uint256 indexed communityId, address indexed newTopEarner, uint256 score);
    event BadgeAwarded(address indexed wallet, uint256 indexed communityId, string reason);
    event CommunityStaked(uint256 indexed communityId, address indexed host, uint256 amount);
    event StakeSlashed(uint256 indexed communityId, uint256 amount);
    event StakeWithdrawn(uint256 indexed communityId, address indexed host, uint256 amount);

    function setUp() public {
        nft = new UserProfileNFT();
        registry = new CommunityRegistry(deployer, address(nft), feeRecipient);

        nft.authorizeWriter(address(registry));
        registry.grantHost(host);

        nft.mintProfile(host, "alice_host");
        nft.mintProfile(user, "bob_user");

        deal(host, 10 ether);
    }

    function _createCommunity() internal returns (uint256 communityId) {
        vm.prank(host);
        communityId = registry.createCommunity{value: STAKE}("Cowork Space A", "Warsaw");
    }

    function _createEvent(uint256 communityId, uint256 minRep) internal returns (uint256 eventId, uint256 endTime) {
        uint256 startTime = block.timestamp + START_OFFSET;
        endTime = startTime + DURATION;
        bytes32 qrHash = keccak256(abi.encodePacked(communityId, block.timestamp));

        vm.prank(host);
        eventId = registry.createEvent(communityId, "April Meetup", startTime, endTime, qrHash, REP_REWARD, minRep);
    }

    function test_profilesMinted() public {
        assertTrue(nft.hasProfile(host));
        assertTrue(nft.hasProfile(user));
        assertFalse(nft.hasProfile(makeAddr("stranger")));

        assertEq(nft.totalSupply(), 2);

        UserProfileNFT.Profile memory hostProfile = nft.getProfile(nft.getTokenIdByWallet(host));
        assertEq(hostProfile.username, "alice_host");

        UserProfileNFT.Profile memory userProfile = nft.getProfile(nft.getTokenIdByWallet(user));
        assertEq(userProfile.username, "bob_user");
    }

    function test_cannotMintDuplicateProfile() public {
        vm.expectRevert("Profile already exists");
        nft.mintProfile(host, "duplicate");
    }

    function test_hostCreatesCommunity() public {
        uint256 communityId = _createCommunity();

        CommunityRegistry.Community memory c = registry.getCommunity(communityId);
        assertEq(c.name, "Cowork Space A");
        assertEq(c.location, "Warsaw");
        assertEq(c.host, host);
        assertTrue(c.active);
        assertEq(registry.getCommunityCount(), 1);
    }

    function test_nonHostCannotCreateCommunity() public {
        vm.prank(user);
        vm.expectRevert("Not a host");
        registry.createCommunity("Fake Space", "Nowhere");
    }

    function test_userJoinsCommunity() public {
        uint256 communityId = _createCommunity();

        vm.prank(user);
        registry.joinCommunity(communityId);

        assertTrue(registry.isMember(communityId, user));
        assertEq(registry.getCommunityMembers(communityId).length, 1);

        uint256[] memory joined = registry.getMemberCommunities(user);
        assertEq(joined.length, 1);
        assertEq(joined[0], communityId);
    }

    function test_userWithoutProfileCannotJoin() public {
        uint256 communityId = _createCommunity();
        address stranger = makeAddr("stranger");

        vm.prank(stranger);
        vm.expectRevert("Must have a profile first");
        registry.joinCommunity(communityId);
    }

    function test_cannotJoinTwice() public {
        uint256 communityId = _createCommunity();

        vm.prank(user);
        registry.joinCommunity(communityId);

        vm.prank(user);
        vm.expectRevert("Already a member");
        registry.joinCommunity(communityId);
    }

    function test_hostCreatesEvent() public {
        uint256 communityId = _createCommunity();
        (uint256 eventId,) = _createEvent(communityId, 0);

        CommunityRegistry.EventRecord memory ev = registry.getEvent(eventId);
        assertEq(ev.communityId, communityId);
        assertEq(ev.name, "April Meetup");
        assertEq(ev.reputationReward, REP_REWARD);
        assertEq(ev.minReputationRequired, 0);
        assertFalse(ev.finalized);
        assertEq(registry.getEventCount(), 1);

        uint256[] memory communityEvents = registry.getCommunityEvents(communityId);
        assertEq(communityEvents.length, 1);
        assertEq(communityEvents[0], eventId);
    }

    function test_eventEligibility_openEvent() public {
        uint256 communityId = _createCommunity();
        (uint256 eventId,) = _createEvent(communityId, 0);

        assertTrue(registry.isEligibleForEvent(user, eventId));
        assertTrue(registry.isEligibleForEvent(makeAddr("stranger"), eventId));
    }

    function test_eventEligibility_gatedEvent() public {
        uint256 communityId = _createCommunity();
        (uint256 eventId,) = _createEvent(communityId, 200); // requires 200 rep

        assertFalse(registry.isEligibleForEvent(user, eventId)); // user has 0 rep
    }

    function test_fullFlow_singleAttendee() public {
        uint256 communityId = _createCommunity();

        vm.prank(user);
        registry.joinCommunity(communityId);

        (uint256 eventId, uint256 endTime) = _createEvent(communityId, 0);

        vm.warp(endTime + 1);

        address[] memory attendees = new address[](1);
        attendees[0] = user;

        vm.expectEmit(true, true, false, false);
        emit AttendanceRecorded(user, eventId);

        vm.expectEmit(true, true, false, true);
        emit LeaderboardUpdated(communityId, user, REP_REWARD);

        vm.expectEmit(true, true, false, false);
        emit BadgeAwarded(user, communityId, "Top community earner");

        vm.prank(host);
        registry.finalizeEvent(eventId, attendees);

        assertEq(nft.getReputation(user, communityId), REP_REWARD);
        assertEq(nft.communityReputation(user, communityId), REP_REWARD);

        assertEq(registry.communityTopEarner(communityId), user);
        assertEq(registry.communityTopScore(communityId), REP_REWARD);

        UserProfileNFT.Badge[] memory badges = nft.getBadges(user);
        assertEq(badges.length, 1);
        assertEq(badges[0].communityId, communityId);

        CommunityRegistry.EventRecord memory ev = registry.getEvent(eventId);
        assertTrue(ev.finalized);
        assertEq(ev.attendeeCount, 1);

        assertTrue(registry.hasAttended(eventId, user));
        assertEq(registry.getEventAttendees(eventId).length, 1);
    }

    function test_leaderboard_multipleAttendeesAcrossEvents() public {
        uint256 communityId = _createCommunity();

        address user2 = makeAddr("user2");
        nft.mintProfile(user2, "charlie");
        vm.prank(user2);
        registry.joinCommunity(communityId);

        vm.prank(user);
        registry.joinCommunity(communityId);

        (uint256 eventId1, uint256 end1) = _createEvent(communityId, 0);
        vm.warp(end1 + 1);

        address[] memory attendees1 = new address[](2);
        attendees1[0] = user;
        attendees1[1] = user2;

        vm.prank(host);
        registry.finalizeEvent(eventId1, attendees1);

        assertEq(nft.getReputation(user, communityId), 100);
        assertEq(nft.getReputation(user2, communityId), 100);
        assertEq(registry.communityTopEarner(communityId), user);

        (uint256 eventId2, uint256 end2) = _createEvent(communityId, 0);
        vm.warp(end2 + 1);

        address[] memory attendees2 = new address[](1);
        attendees2[0] = user2;

        vm.prank(host);
        registry.finalizeEvent(eventId2, attendees2);

        assertEq(nft.getReputation(user2, communityId), 200);
        assertEq(registry.communityTopEarner(communityId), user2);
        assertEq(registry.communityTopScore(communityId), 200);

        UserProfileNFT.Badge[] memory badges2 = nft.getBadges(user2);
        assertEq(badges2.length, 1);
        assertEq(badges2[0].communityId, communityId);
    }

    function test_cannotFinalizeBeforeEventEnds() public {
        uint256 communityId = _createCommunity();
        (uint256 eventId,) = _createEvent(communityId, 0);

        address[] memory attendees = new address[](1);
        attendees[0] = user;

        vm.prank(host);
        vm.expectRevert("Event still active");
        registry.finalizeEvent(eventId, attendees);
    }

    function test_cannotFinalizeTwice() public {
        uint256 communityId = _createCommunity();
        (uint256 eventId, uint256 endTime) = _createEvent(communityId, 0);
        vm.warp(endTime + 1);

        address[] memory attendees = new address[](1);
        attendees[0] = user;

        vm.prank(host);
        registry.finalizeEvent(eventId, attendees);

        vm.prank(host);
        vm.expectRevert("Already finalized");
        registry.finalizeEvent(eventId, attendees);
    }

    function test_cannotSubmitDuplicateAttendee() public {
        uint256 communityId = _createCommunity();
        (uint256 eventId, uint256 endTime) = _createEvent(communityId, 0);
        vm.warp(endTime + 1);

        address[] memory attendees = new address[](2);
        attendees[0] = user;
        attendees[1] = user; // duplicate

        vm.prank(host);
        vm.expectRevert("Duplicate attendee");
        registry.finalizeEvent(eventId, attendees);
    }

    function test_reputationGatedEventBlocksIneligibleUser() public {
        uint256 communityId = _createCommunity();

        (uint256 eventId1, uint256 end1) = _createEvent(communityId, 0);
        vm.warp(end1 + 1);
        address[] memory first = new address[](1);
        first[0] = user;
        vm.prank(host);
        registry.finalizeEvent(eventId1, first);

        (uint256 eventId2,) = _createEvent(communityId, 200);
        assertFalse(registry.isEligibleForEvent(user, eventId2));
    }

    // ── Staking tests ──────────────────────────────────────────────────────

    function test_createCommunityRequiresStake() public {
        vm.prank(host);
        vm.expectRevert("Insufficient stake");
        registry.createCommunity{value: 0.001 ether}("Too Cheap", "Nowhere");
    }

    function test_createCommunityStoresStake() public {
        uint256 communityId = _createCommunity();
        assertEq(registry.communityStake(communityId), STAKE);
        assertEq(address(registry).balance, STAKE);
    }

    function test_earlyDeactivationSlashesStake() public {
        uint256 communityId = _createCommunity();
        uint256 before = feeRecipient.balance;

        vm.prank(host);
        registry.deactivateCommunity(communityId);

        assertEq(feeRecipient.balance, before + STAKE);
        assertEq(registry.communityStake(communityId), 0);
    }

    function test_withdrawStakeAfterMinPeriod() public {
        uint256 communityId = _createCommunity();
        uint256 before = host.balance;

        vm.warp(block.timestamp + 30 days + 1);

        vm.prank(host);
        registry.withdrawStake(communityId);

        assertEq(host.balance, before + STAKE);
        assertEq(registry.communityStake(communityId), 0);
    }

    function test_withdrawStakeTooEarlyReverts() public {
        uint256 communityId = _createCommunity();

        vm.warp(block.timestamp + 10 days);

        vm.prank(host);
        vm.expectRevert("Too early");
        registry.withdrawStake(communityId);
    }

    function test_noSlashAfterMinPeriod() public {
        uint256 communityId = _createCommunity();

        vm.warp(block.timestamp + 30 days + 1);

        uint256 feeBefore = feeRecipient.balance;
        vm.prank(host);
        registry.deactivateCommunity(communityId);

        assertEq(feeRecipient.balance, feeBefore); // no slash
        assertEq(registry.communityStake(communityId), STAKE); // still withdrawable
    }
}
