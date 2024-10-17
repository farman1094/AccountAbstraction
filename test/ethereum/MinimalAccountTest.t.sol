// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MinimalAccount} from "src/ethereum/MinimalAccount.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployMinimalAccount} from "script/DeployMinimalAccount.s.sol";
import {USDCMock} from "test/mocks/USDCMock.sol";

contract MinimalAccountTest is Test {

    MinimalAccount public minimalAccount;
    HelperConfig public helperConfig;
    HelperConfig.NetworkConfig public config;
    USDCMock tokenUsdc;
    function setUp() public {
        // vm.startBroadcast(msg.sender);
        DeployMinimalAccount deployer = new DeployMinimalAccount();
        (helperConfig, minimalAccount) = deployer.run();
        // vm.stopBroadcast();
        config = helperConfig.getConfig();
        tokenUsdc = USDCMock(config.usdc);

    }
    

    function testToRunExecute() public {
        tokenUsdc.totalSupply();
    // function execute(address dest, uint256 value, bytes calldata functionData) external requireEntryPointOrOwner {
    address dest = address(tokenUsdc);
    uint256 value = 0;
    //     function allowance(address owner, address spender) external view returns (uint256);

    vm.prank(msg.sender);
    bytes memory functionData = abi.encodeWithSignature("allowance(address,address)", msg.sender, address(minimalAccount));
    minimalAccount.execute(dest, value, functionData);

    // function transfer(address to, uint256 value) external returns (bool);
    bytes memory transferFromData = abi.encodeWithSignature("transfer(address,uint256)", address(minimalAccount), 5e18);
    tokenUsdc.balanceOf(msg.sender);
    vm.prank(address(this));
    minimalAccount.execute(dest, value, transferFromData);


}



}

/* USDC approval
msg.sender -> MinimalAccount
approve some amount
USDC contract
come from the entrypoint -> MinimalAccount -> USDC contract
*/