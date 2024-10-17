// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {HelperConfig} from "script/HelperConfig.s.sol";
import {Script} from "forge-std/Script.sol";
import {MinimalAccount} from "src/ethereum/MinimalAccount.sol";

contract DeployMinimalAccount is Script {
    HelperConfig.NetworkConfig config;

    function run() external returns (HelperConfig, MinimalAccount) {
        HelperConfig helperConfig = new HelperConfig();
        config = helperConfig.getConfig();

        vm.startBroadcast(config.account);
        MinimalAccount minimalAccount = new MinimalAccount(config.entryPoint);
        minimalAccount.transferOwnership(msg.sender);
        vm.stopBroadcast();

        return (helperConfig, minimalAccount);
    }
}
