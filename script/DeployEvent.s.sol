// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface ICommunityRegistry {
    function createEvent(
        uint256 communityId,
        string calldata name,
        uint256 startTime,
        uint256 endTime,
        bytes32 qrHash,
        uint256 reputationReward,
        uint256 minReputationRequired
    ) external returns (uint256 eventId);
}

contract DeployEvent is Script {
    /*
    * @notice This script deploys a new event to an existing CommunityRegistry contract.

    */
    function run() external {
        uint256 hostPrivateKey = vm.envUint("PRIVATE_KEY");

        address registryAddr = vm.envAddress("REGISTRY_ADDRESS");
        uint256 communityId = vm.envUint("COMMUNITY_ID");
        string memory eventName = vm.envString("EVENT_NAME");
        uint256 startTime = vm.envUint("EVENT_START");
        uint256 endTime = vm.envUint("EVENT_END");
        bytes32 qrHash = vm.envBytes32("EVENT_QR_HASH");
        uint256 repReward = vm.envUint("EVENT_REP_REWARD");
        uint256 minRep = vm.envUint("EVENT_MIN_REP");

        vm.startBroadcast(hostPrivateKey);
        uint256 eventId = ICommunityRegistry(registryAddr).createEvent(
            communityId,
            eventName,
            startTime,
            endTime,
            qrHash,
            repReward,
            minRep
        );
        vm.stopBroadcast();

        console.log("Event created with ID:", eventId);
    }
}
