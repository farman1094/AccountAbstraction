// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";
import {MinimalAccount} from "src/ethereum/MinimalAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {DeployMinimalAccount} from "./DeployMinimalAccount.s.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract SendUserPackedUserOp is Script {
    using MessageHashUtils for bytes32;
    // address minimalAccountAddrForOwnEntyPoint = 0x1d6630fca32021aB5068ab646AAc800934AdbC80;
    // address minimalAccountAddr = 0xD4CD7d924031D104FC94e7CCFBdAB2b3902f8547;

    address minimalAccountAddr = 0x1d6630fca32021aB5068ab646AAc800934AdbC80;
    HelperConfig.NetworkConfig sepConfig;
    address USER = 0x701477467321474712bACA6779FE8926528B3c93;
    address randomUser = 0x264F7948c23da2233D3458F1B4e2554f0e56c9Ca;
    uint256 userKey = vm.envUint("SEPO_ENV");

    function run() external {
        HelperConfig helperConfig = new HelperConfig();
        sepConfig = helperConfig.getConfig();

        bytes memory transferData =
            abi.encodeWithSignature("transferFrom(address,address,uint256)", USER, randomUser, 5e18);

        bytes memory executeData =
            abi.encodeWithSignature("execute(address,uint256,bytes)", sepConfig.usdc, 0, transferData);

        PackedUserOperation memory userOPS = generateSignedUserOperation(executeData, sepConfig, minimalAccountAddr);
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = userOPS;

        vm.startBroadcast();
        IEntryPoint(sepConfig.entryPoint).handleOps(ops, payable(sepConfig.account));
        vm.stopBroadcast();
    }

    // /        bytes32 digest = userOpHash.toEthSignedMessageHash(); // check

    function generateSignedUserOperation(
        bytes memory callData,
        HelperConfig.NetworkConfig memory config,
        address minimalAccount
    ) public view returns (PackedUserOperation memory) {
        uint256 nonce = vm.getNonce(minimalAccount) - 1;
        // 1. Generate the unsigned data
        PackedUserOperation memory userOp = _generateUnsignedUserOperation(callData, minimalAccount, nonce);
        // 2. Get the userOpHash though the entryPoint
        // Coming
        console2.log("Coming....");
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOp);
        console2.log("....");
        bytes32 digest = userOpHash.toEthSignedMessageHash(); // check

        // 3. Sign it, and return
        uint256 anvilPkey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        uint8 v;
        bytes32 r;
        bytes32 s;
        if (block.chainid == 31337) {
            //ANVIL
            (v, r, s) = vm.sign(anvilPkey, digest);
        } else {
            (v, r, s) = vm.sign(userKey, digest);
        }
        userOp.signature = abi.encodePacked(r, s, v);
        /**
         * @dev for sepolia and other
         */
        // foundry will take the private key from --account, and sign the message
        // vm.sign(config.account,digest );
        return userOp;
    }

    function _generateUnsignedUserOperation(bytes memory callData, address sender, uint256 nonce)
        internal
        pure
        returns (PackedUserOperation memory)
    {
        uint128 verificationGasLimit = 16777216;
        uint128 callGasLimit = verificationGasLimit;
        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;
        return PackedUserOperation({
            sender: sender,
            nonce: nonce,
            initCode: hex"",
            callData: callData,
            accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | uint256(callGasLimit)),
            preVerificationGas: verificationGasLimit,
            gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | uint256(maxFeePerGas)),
            paymasterAndData: hex"",
            signature: hex""
        });
    }
}

/**
 * IMPORTANT ADDRESSES
 * USDC Mock: 0xD5457C30d3fA8DED4abD8bC4450c55D43aCEEe2F
 * Main Enrty Point: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789
 * Minimal Account address: 0xD4CD7d924031D104FC94e7CCFBdAB2b3902f8547 (deployed as per Main Entry Point)
 * Own Entry Point: 0xef5116bF4B6A157698c2aFF675349d01cAA27927
 * Minimal Account address: 0x1d6630fca32021aB5068ab646AAc800934AdbC80 (deployed as per own entry Point)
 * One of the failed transaction: 0xca3e6d00ae57f4d89310b661cca8d275890b35d5478cce13f6cd909db9fb0ef7
 */
