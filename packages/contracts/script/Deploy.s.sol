// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {UserProfileNFT} from "../src/identity/UserProfileNFT.sol";
import {CommunityRegistry} from "../src/registry/CommunityRegistry.sol";

contract Deploy is Script {
    function run() external {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        uint256 deployerPrivateKey = config.deployerPrivateKey;
        address deployer = config.deployer;

        console.log("Deploying with account:", deployer);
        console.log("Balance:", deployer.balance);
        console.log("Chain ID:", block.chainid);

        vm.startBroadcast(deployerPrivateKey);

        UserProfileNFT userProfileNft = new UserProfileNFT();
        console.log("UserProfileNft:", address(userProfileNft));

        CommunityRegistry registry = new CommunityRegistry(
            deployer,
            address(userProfileNft),
            deployer // feeRecipient: slashed stakes go to deployer
        );
        console.log("CommunityRegistry:", address(registry));

        userProfileNft.authorizeWriter(address(registry));

        registry.grantHost(deployer);

        vm.stopBroadcast();

        console.log("");
        console.log("=== Deployment Complete ===");
        console.log(
            string.concat(
                '{"chainId":',
                vm.toString(block.chainid),
                ',"UserProfileNft":"',
                vm.toString(address(userProfileNft)),
                '","CommunityRegistry":"',
                vm.toString(address(registry)),
                '"}'
            )
        );
    }
}
