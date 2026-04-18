// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

interface ICommunityRegistry {
    function finalizeEvent(uint256 eventId, address[] calldata attendees) external;
}

// Submits the confirmed attendee list for a past event.
// Attendance collection (QR scanning) happens offchain — this script writes the result onchain.
//
// Required env vars:
//   PRIVATE_KEY        — host wallet private key
//   REGISTRY_ADDRESS   — deployed CommunityRegistry address
//   EVENT_ID           — ID of the event to finalize
//   ATTENDEES_FILE     — path to a JSON file containing an array of attendee addresses
//
// attendees.json format:
//   ["0xAddress1", "0xAddress2", "0xAddress3"]
//
// Example:
//   PRIVATE_KEY=0x... \
//   REGISTRY_ADDRESS=0x... \
//   EVENT_ID=1 \
//   ATTENDEES_FILE=./attendees.json \
//   forge script script/FinalizeEvent.s.sol --rpc-url arb_sepolia --broadcast
contract FinalizeEvent is Script {
    function run() external {
        uint256 hostPrivateKey = vm.envUint("PRIVATE_KEY");
        address registryAddr = vm.envAddress("REGISTRY_ADDRESS");
        uint256 eventId = vm.envUint("EVENT_ID");
        string memory attendeesFile = vm.envString("ATTENDEES_FILE");

        string memory json = vm.readFile(attendeesFile);
        address[] memory attendees = vm.parseJsonAddressArray(json, ".");

        console.log("Finalizing event ID:", eventId);
        console.log("Attendee count:", attendees.length);
        for (uint256 i = 0; i < attendees.length; i++) {
            console.log(" -", attendees[i]);
        }

        vm.startBroadcast(hostPrivateKey);
        ICommunityRegistry(registryAddr).finalizeEvent(eventId, attendees);
        vm.stopBroadcast();

        console.log("Event finalized. AttendanceRecorded events emitted onchain.");
    }
}
