// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDCMock is ERC20 {
    constructor() ERC20("USDC", "USDC") {
        _mint(msg.sender, 10e18);
    }
}
