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

    address randomAddress = makeAddr("randomAddress");

    function setUp() public {
        // vm.startBroadcast(msg.sender);
        DeployMinimalAccount deployer = new DeployMinimalAccount();
        (helperConfig, minimalAccount) = deployer.run();
        // vm.stopBroadcast();
        config = helperConfig.getConfig();
        tokenUsdc = USDCMock(config.usdc);
    }

    function testToRunExecute() public {
        // Arrange
        tokenUsdc.totalSupply();
        // function execute(address dest, uint256 value, bytes calldata functionData) external requireEntryPointOrOwner {
        address dest = address(tokenUsdc);
        uint256 value = 0;

        vm.startPrank(msg.sender); //0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f
        tokenUsdc.balanceOf(msg.sender);
        tokenUsdc.approve(address(minimalAccount), 5e18);

        // function approve(address spender, uint256 value) public virtual returns (bool) {
        bytes memory functionData = abi.encodeWithSignature("balanceOf(address)", msg.sender);
        minimalAccount.execute(dest, value, functionData);

        // function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        // bytes memory transferFromData = abi.encodeWithSignature("transferFrom(address,address,uint256)",msg.sender, address(minimalAccount), 5e18);
        bytes memory transferFromData =
            abi.encodeWithSelector(tokenUsdc.transferFrom.selector, msg.sender, address(minimalAccount), 5e18);
        // ACT
        minimalAccount.execute(dest, value, transferFromData);

        // ASSERT
        assertEq(tokenUsdc.balanceOf(msg.sender), tokenUsdc.balanceOf(address(minimalAccount)));
        vm.stopPrank();
    }

    function testNonOwnerCannotExecute() public {
        // Arrange
        address dest = address(tokenUsdc);
        uint256 value = 0;
        bytes memory transferFromData = abi.encodeWithSignature("balanceOf(address)", msg.sender);

        vm.prank(randomAddress); //random address

        //ACT & ASSERT
        vm.expectRevert(MinimalAccount.MinimalAccount__NotFromEntryPointOrOwner.selector);
        minimalAccount.execute(dest, value, transferFromData);
    }

    function testValidationOfUserOp() public {}
}

/* USDC approval
msg.sender -> MinimalAccount
approve some amount
USDC contract
come from the entrypoint -> MinimalAccount -> USDC contract
*/
