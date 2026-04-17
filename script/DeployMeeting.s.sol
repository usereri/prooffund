// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/meetings/MeetingContract.sol";

/**
 * @title DeployMeeting
 * @notice Deploy a new MeetingContract per meeting (factory pattern)
 * @dev Takes registry address and deploys meeting-specific contract
 */
contract DeployMeeting is Script {
    function run() external {
        uint256 hostPrivateKey = vm.envUint("PRIVATE_KEY");
        address host = vm.addr(hostPrivateKey);

        // Meeting parameters from env or override
        address registry = vm.envAddress("REGISTRY_ADDRESS");
        uint256 meetingId = vm.envUint("MEETING_ID");
        string memory title = vm.envString("MEETING_TITLE");
        uint256 startTime = vm.envUint("MEETING_START_TIME");
        uint256 endTime = vm.envUint("MEETING_END_TIME");
        bytes32 qrHash = vm.envBytes32("MEETING_QR_HASH");

        console.log("Deploying MeetingContract:");
        console.log("Host:", host);
        console.log("Registry:", registry);
        console.log("Meeting ID:", meetingId);
        console.log("Title:", title);
        console.log("Start Time:", startTime);
        console.log("End Time:", endTime);
        console.log("QR Hash:", vm.toString(qrHash));

        vm.startBroadcast(hostPrivateKey);

        MeetingContract meetingContract = new MeetingContract(
            registry,
            meetingId,
            title,
            startTime,
            endTime,
            qrHash,
            msg.sender // factory address (this script deployer)
        );

        console.log("MeetingContract deployed at:", address(meetingContract));

        vm.stopBroadcast();

        console.log("");
        console.log("=== New Meeting ===");
        console.log("Contract Address:", address(meetingContract));
        console.log("QR Hash:", vm.toString(qrHash));
    }
}
