// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AggregatorV3Interface} from "./MockOracle.sol";
import {console2} from "forge-std/Test.sol";

error InvalidPosition();
error NotEnoughTokensInPool();
error PositionAlreadyOpen();

contract Perp is ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum PositionType {
        LONG,
        SHORT
    }

    struct Position {
        PositionType positionType;
        uint256 size;
        uint256 collateral;
        uint256 openPrice;
        uint256 createdAt;
    }

    uint256 constant PRECISION_WBTC_USD = 1e10;
    uint256 constant UTILIZATION_PERCENT_BPS = 9000; //90%
    uint256 MAX_LEVERAGE = 10;
    address chainlinkFeed;
    address usdc;
    address liquidityPool;
    address wbtc;

    uint256 public openInterestLongWbtc;
    uint256 public openInterestShortWbtc;
    uint256 public openInterestLongUsd;
    uint256 public openInterestShortUsd;
    mapping(address => Position) public positions;

    constructor(address _chainlinkFeed, address _usdc, address _liquidityPool, address _wbtc) {
        chainlinkFeed = _chainlinkFeed;
        usdc = _usdc;
        liquidityPool = _liquidityPool;
        wbtc = _wbtc;
    }

    function openPosition(uint256 size, uint256 collateral, PositionType positionType) public nonReentrant {
        if (size == 0 || collateral == 0) revert InvalidPosition();
        uint256 price = getWbtcPrice();
        uint256 sizeInUsd = price * size / PRECISION_WBTC_USD;
        console2.log("sizeInUsd", sizeInUsd);
        uint256 leverage = sizeInUsd / collateral;
        console2.log("leverage", leverage);

        if (leverage > MAX_LEVERAGE) revert InvalidPosition();

        if (sizeInUsd > getPoolUsableBalance()) revert NotEnoughTokensInPool();
        IERC20(usdc).safeTransferFrom(msg.sender, address(liquidityPool), collateral);
        if (positionType == PositionType.LONG) {
            openInterestLongWbtc += size;
            openInterestLongUsd += sizeInUsd;
        } else if (positionType == PositionType.SHORT) {
            openInterestShortWbtc += size;
            openInterestShortUsd += sizeInUsd;
        } else {
            revert InvalidPosition();
        }
        positions[msg.sender] = Position(positionType, size, collateral, price, block.timestamp);
    }

    function getPoolUsableBalance() public view returns (uint256) {
        uint256 poolBalance = IERC20(usdc).balanceOf(liquidityPool);
        console2.log("poolBalance", poolBalance);
        uint256 totalOpenInterest = openInterestLongWbtc + openInterestShortWbtc;
        uint256 totalOpenInterestUsd = totalOpenInterest * getWbtcPrice() / PRECISION_WBTC_USD;
        uint256 maxUsableBalance = poolBalance * UTILIZATION_PERCENT_BPS / 10000;

        if (totalOpenInterestUsd < maxUsableBalance) {
            return maxUsableBalance - totalOpenInterestUsd;
        } else {
            return 0;
        }
    }

    function getWbtcPrice() public view returns (uint256) {
        (, int256 answer,,,) = AggregatorV3Interface(chainlinkFeed).latestRoundData();
        return uint256(answer);
    }
}
