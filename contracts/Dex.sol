// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract IsDex is ReentrancyGuard, Ownable, ERC20 {
    IERC20 public token1;
    IERC20 public token2;
    uint256 public constant PRICE_PRECISION = 1e18;
    uint256 public constant FEE_PERCENTAGE = 3;
    uint256 public constant FEE_DENOMINATOR = 1000;

    uint256 public price;
    uint256 public totalToken1;
    uint256 public totalToken2;

    struct UserInfo {
        uint256 token1Balance;
        uint256 token2Balance;
        uint256 lastUpdateTime;
    }

    mapping(address => UserInfo) public userInfo;

    event Swap(
        address indexed user,
        uint256 token1Amount,
        uint256 token2Amount,
        bool token1ToToken2
    );
    event LiquidityAdded(address indexed user,uint256 token1Amount,uint256 token2Amount,uint256 lpTokens);
    event LiquidityRemoved(address indexed user, uint256 token1Amount, uint256 token2Amount, uint256 lpTokens);
    event PriceUpdated(uint256 newPrice);

    constructor(address _token1, address _token2, uint256 _initialPrice) ERC20("LP TOKEN", "LPT"){
        require(_token1 != address(0) && _token2 != address(0), "Invalid token address");
        require(_initialPrice > 0, "Invalid initial Price");

        token1 = IERC20(_token1);
        token2 = IERC20(_token2);
        price = _initialPrice;
    }
}
