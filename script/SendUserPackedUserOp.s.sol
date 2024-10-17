// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// import {Script} from "forge-std/Script.sol";
// import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";
// import {MinimalAccount} from "src/ethereum/MinimalAccount.sol";
// import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
// import {DeployMinimalAccount} from "./DeployMinimalAccount.s";

// contract SendUserPackedUserOp is Script {
//     function run() external {

//     }

//     function generatSignedUserOperation(bytes memory callData, address sender) public returns(PackedUserOperation memory) {
//         // 2. Sign it, and return
//         uint256 nonce = vm.getNonce(sender);
//         PackedUserOperation memory unsignedUserOperation = _generateUnsignedUserOperation(callData,  sender, nonce);
//         bytes32 userOpHash = EntryPoint(entryPoint).hashUserOp(unsignedUserOperation);

//     }

//     function _generateUnsignedUserOperation(bytes memory callData, address sender, uint256 nonce) internal pure returns(PackedUserOperation memory) {
//     // Generate the unsigned data
//     uint128 verificationGasLimit = 16777216;
//     uint128 callGasLimit = verificationGasLimit;
//     uint128 maxPriorityFeePerGas = 256;
//     uint128 maxFeePerGas = maxPriorityFeePerGas;
//     return PackedUserOperation ({
//         sender: sender,
//         nonce: nonce,
//         initCode: hex"",
//         callData: callData,
//         accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | uint256(callGasLimit)),
//         preVerificationGas: verificationGasLimit,
//         gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | uint256(maxFeePerGas)),
//         paymasterAndData: hex"",
//         signature: hex""


//     });
    
//     }
// }
