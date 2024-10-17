// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";
import {USDCMock} from "test/mocks/USDCMock.sol";

contract HelperConfig is Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        address entryPoint;
        address account;
        address usdc;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainid => NetworkConfig) public networkConfigs;

    uint256 constant CHAIN_ID_ANVIL = 31337;
    uint256 constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint256 constant ETH_SEPOLIA_CHAIN_ID = 11155111;

    address constant BURNER_WALLET  = 0x701477467321474712bACA6779FE8926528B3c93;
    address constant ANVIL_DEFAULT_SENDER  = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (chainId == CHAIN_ID_ANVIL) {
            return getOrCreateAnvilEthConfig();
        } else if (networkConfigs[chainId].account != address(0)) {
            return networkConfigs[chainId];
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getEthSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789, account: BURNER_WALLET, usdc: address(0) });
    }

    function getZkSyncSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({entryPoint: address(0), account: BURNER_WALLET, usdc: address(0) });
    }

    function getOrCreateAnvilEthConfig() public  returns (NetworkConfig memory) {
        if (localNetworkConfig.account != address(0)) {
            return localNetworkConfig;
        }
        vm.startBroadcast(ANVIL_DEFAULT_SENDER);
        EntryPoint entryPoint = new EntryPoint();
        USDCMock usdMock = new USDCMock();
        vm.stopBroadcast();
        return NetworkConfig ({entryPoint: address(entryPoint), account: ANVIL_DEFAULT_SENDER, usdc: address(usdMock)});
    }
}
