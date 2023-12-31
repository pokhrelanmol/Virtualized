// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {LiquidityPool} from "../src/LiquidityPool.sol";
import {MockUSDC} from "../src/MockUSDC.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LiqudityPoolTest is Test {
    LiquidityPool pool;
    MockUSDC usdc;

    function setUp() public {
        usdc = new MockUSDC();
        pool = new LiquidityPool(address(usdc));
    }

    function test_deposit() public {
        usdc.approve(address(pool), 1000e8);
        pool.deposit(1000e8, address(this));
        assertEq(pool.balanceOf(address(this)), 1000e8);
        assertEq(usdc.balanceOf(address(pool)), 1000e8);
    }

    function test_withdraw() public {
        usdc.approve(address(pool), 1000e8);
        pool.deposit(1000e8, address(this));
        pool.withdraw(1000e8, address(this), address(this));
        assertEq(pool.balanceOf(address(this)), 0);
        assertEq(usdc.balanceOf(address(pool)), 0);
    }
}
