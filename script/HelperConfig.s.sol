// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

abstract contract CodeConstants {
    uint256 public constant ETH_SEPOLIA_CHAINID = 11155111;
    uint256 public constant ARB_SEPOLIA_CHAINID = 421614;
    uint256 public constant LOCAL_CHAINID = 31337;
}

contract HelperConfig is Script, CodeConstants {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 deployerPrivateKey;
        address deployer;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAINID] = getSepoliaConfig();
        networkConfigs[ARB_SEPOLIA_CHAINID] = getArbSepoliaConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].deployer != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAINID) {
            return getOrCreateAnvilConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            deployerPrivateKey: vm.envUint("PRIVATE_KEY"), deployer: 0xBbCbB8362Dbd3a3Fcbc7AE9c0D808c6c214Ed3E2
        });
    }

    function getArbSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            deployerPrivateKey: vm.envUint("PRIVATE_KEY"), deployer: 0xBbCbB8362Dbd3a3Fcbc7AE9c0D808c6c214Ed3E2
        });
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.deployer != address(0)) {
            return localNetworkConfig;
        }
        localNetworkConfig = NetworkConfig({
            deployerPrivateKey: vm.envUint("ANVIL_PRIVATE_KEY"), deployer: vm.addr(vm.envUint("ANVIL_PRIVATE_KEY"))
        });
        return localNetworkConfig;
    }
}
