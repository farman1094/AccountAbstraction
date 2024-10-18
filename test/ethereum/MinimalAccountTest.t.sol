// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MinimalAccount} from "src/ethereum/MinimalAccount.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployMinimalAccount} from "script/DeployMinimalAccount.s.sol";
import {SendUserPackedUserOp} from "script/SendUserPackedUserOp.s.sol";
import {USDCMock} from "test/mocks/USDCMock.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";

contract MinimalAccountTest is Test {
    using MessageHashUtils for bytes32;

    MinimalAccount public minimalAccount;
    HelperConfig public helperConfig;
    HelperConfig.NetworkConfig public config;
    USDCMock tokenUsdc;
    SendUserPackedUserOp public sendUserPackedUserOp;
    address constant ANVIL_DEFAULT_SENDER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    address randomAddress = makeAddr("randomAddress");

    function setUp() public {
        // vm.startBroadcast(msg.sender);
        DeployMinimalAccount deployer = new DeployMinimalAccount();
        sendUserPackedUserOp = new SendUserPackedUserOp();
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

        vm.startPrank(ANVIL_DEFAULT_SENDER); //0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f
        tokenUsdc.balanceOf(ANVIL_DEFAULT_SENDER);
        tokenUsdc.approve(address(minimalAccount), 5e18);

        // function approve(address spender, uint256 value) public virtual returns (bool) {
        bytes memory functionData = abi.encodeWithSignature("balanceOf(address)", ANVIL_DEFAULT_SENDER);
        minimalAccount.execute(dest, value, functionData);

        // function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        // bytes memory transferFromData = abi.encodeWithSignature("transferFrom(address,address,uint256)",msg.sender, address(minimalAccount), 5e18);
        bytes memory transferFromData =
            abi.encodeWithSelector(tokenUsdc.transferFrom.selector, ANVIL_DEFAULT_SENDER, address(minimalAccount), 5e18);
        // ACT
        minimalAccount.execute(dest, value, transferFromData);

        // ASSERT
        assertEq(tokenUsdc.balanceOf(ANVIL_DEFAULT_SENDER), tokenUsdc.balanceOf(address(minimalAccount)));
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

    function testRecoveredSignerOp() public {
        // Arrange
        vm.startPrank(ANVIL_DEFAULT_SENDER); //0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f
        tokenUsdc.approve(address(minimalAccount), 5e18);
        bytes memory transferData = abi.encodeWithSignature(
            "transferFrom(address,address,uint256)", ANVIL_DEFAULT_SENDER, address(minimalAccount), 5e18
        );
        bytes memory executeData =
            abi.encodeWithSignature("execute(address,uint256,bytes)", address(tokenUsdc), 0, transferData);
        //ACT
        PackedUserOperation memory userOp =
            sendUserPackedUserOp.generateSignedUserOperation(executeData, config, address(minimalAccount));
        // (uint8 v, bytes32 r, bytes32 s) = abi.decode(userOp.signature, (uint8, bytes32, bytes32));
        // bytes32 signature = userOp.signature;
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOp);
        address signer = ECDSA.recover(userOpHash.toEthSignedMessageHash(), userOp.signature);

        //ASSERT
        assertEq(signer, ANVIL_DEFAULT_SENDER);
        vm.stopPrank();
    }

    /**
     * 1 sign user op
     * 2 validate user op
     * 3 assert the result
     */
    function testValidationOfUserOp() public {
        // Arrange
        tokenUsdc.approve(address(minimalAccount), 5e18);
        bytes memory transferData = abi.encodeWithSignature(
            "transferFrom(address,address,uint256)", ANVIL_DEFAULT_SENDER, address(minimalAccount), 5e18
        );
        bytes memory executeData =
            abi.encodeWithSignature("execute(address,uint256,bytes)", address(tokenUsdc), 0, transferData);

        //ACT
        PackedUserOperation memory userOp =
            sendUserPackedUserOp.generateSignedUserOperation(executeData, config, address(minimalAccount));
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOp);
        uint256 MISSING_ACOOUNT_FUNDS = 1e18;
        vm.prank(config.entryPoint);
        uint256 num = minimalAccount.validateUserOp(userOp, userOpHash, MISSING_ACOOUNT_FUNDS);

        //ASSERT
        assertEq(num, SIG_VALIDATION_SUCCESS);
    }

    function testEntryPointCanExecuteCommands() public {
        // Arrange
        vm.prank(ANVIL_DEFAULT_SENDER); //0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f
        tokenUsdc.approve(address(minimalAccount), 5e18);
        bytes memory transferData = abi.encodeWithSignature(
            "transferFrom(address,address,uint256)", ANVIL_DEFAULT_SENDER, address(minimalAccount), 5e18
        );
        bytes memory executeData =
            abi.encodeWithSignature("execute(address,uint256,bytes)", address(tokenUsdc), 0, transferData);

        PackedUserOperation memory userOp =
            sendUserPackedUserOp.generateSignedUserOperation(executeData, config, address(minimalAccount));
        // bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOp);
        vm.deal(address(minimalAccount), 1e18);
        // address(minimalAccount).balance;

        //ACT
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = userOp;

        vm.prank(randomAddress);
        IEntryPoint(config.entryPoint).handleOps(ops, payable(randomAddress));

        //ASSERT
        assertEq(tokenUsdc.balanceOf(ANVIL_DEFAULT_SENDER), tokenUsdc.balanceOf(address(minimalAccount)));
    }

    function testViewMustNotRevert() public view {
        minimalAccount.getEntryPoint();
    }
}

/* USDC approval
msg.sender -> MinimalAccount
approve some amount
USDC contract
come from the entrypoint -> MinimalAccount -> USDC contract
*/
