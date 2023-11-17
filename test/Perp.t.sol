// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {LiquidityPool} from "../src/LiquidityPool.sol";
import {MockBTC} from "../src/MockBTC.sol";
import {MockUSDC} from "../src/MockUSDC.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MockV3Aggregator} from "../src/MockOracle.sol";
import "../src/Perp.sol";

contract PerpTest is Test {
    LiquidityPool pool;
    MockBTC btc;
    MockV3Aggregator oracle;
    Perp perp;
    MockUSDC usdc;

    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    function setUp() public {
        btc = new MockBTC();
        usdc = new MockUSDC();
        pool = new LiquidityPool(address(usdc));
        oracle = new MockV3Aggregator(8,20000e8);
        perp = new Perp(address(oracle),address(usdc), address(pool), address(btc));

        usdc.mint(user1, 10000e6);
        usdc.mint(user2, 10000e6);
    }

    function depositToPool(uint256 amount) public {
        usdc.approve(address(pool), amount);
        pool.deposit(amount, address(this));
    }

    function test_openPosition() public {
        depositToPool(100000e6);
        vm.startPrank(user1);
        usdc.approve(address(perp), 10000e6);
        perp.openPosition(1e8, 10000e6, Perp.PositionType.LONG);
        (Perp.PositionType positionType, uint256 size, uint256 collateral, uint256 openPrice, uint256 createdAt) =
            perp.positions(address(user1));

        assertEq(size, 1e8);
        assertEq(collateral, 10000e6);
        assert(positionType == Perp.PositionType.LONG);
        assertEq(openPrice, 20000e8);
        assertEq(createdAt, block.timestamp);

        vm.stopPrank();
    }
}
