// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";

contract HelperConfig is Script {
    address private i_entryPoint;
    address sepoliaAddress = address(0);
    EntryPoint entryPoint;

    function checkChain() internal returns (address entryPointAddr) {
        if (block.chainid == 31337) {
            anvil();
        } else if (block.chainid == 11155111) {
            return sepoliaAddress;
        }
    }

    function anvil() internal returns (address) {
        vm.startBroadcast();
        entryPoint = new EntryPoint();
        vm.stopBroadcast();
        return address(entryPoint);
    }

    function run() external returns (address) {
        i_entryPoint = checkChain();
        return i_entryPoint;
    }
}
