// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockBTC is ERC20 {
    constructor() ERC20("MockBTC", "MBTC") {
        _mint(msg.sender, 1000000e8);
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }
}
