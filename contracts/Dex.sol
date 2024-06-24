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

    function swapToken1forToken2(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        uint256 token2Amount = (_amount * price) / PRICE_PRECISION;
        uint256 fee = (token2Amount * FEE_PERCENTAGE) / FEE_DENOMINATOR;
        uint256 token2AmountAfterFee = token2Amount - fee;

        require(token2.balanceOf(address(this)) >= token2AmountAfterFee, "Insufficient Liquidity"); 

        require(token1.transferFrom(msg.sender, address(this), _amount), "Transfer of token1 failed"); 
        require(token2.transfer(msg.sender, token2AmountAfterFee), "Transfer of token2 failed");

        totalToken1 += _amount;
        totalToken2 -= token2AmountAfterFee;

        _updatePrice();
        emit Swap(msg.sender, _amount, token2AmountAfterFee, true);
    }

    function swapToken2forToken1(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        uint256 token1Amount = (_amount * PRICE_PRECISION) / price;
        uint256 fee = (token1Amount * FEE_PERCENTAGE) / FEE_DENOMINATOR;
        uint256 token1AmountAfterFee = token1Amount - fee;

        require(token1.balanceOf(address(this)) >= token1AmountAfterFee, "Insufficient Liquidity");
        require(token2.transferFrom(msg.sender, address(this), _amount), "Transfer of token2 failed");
        require(token1.transfer(msg.sender, token1AmountAfterFee), "Transfer of token1 failed");

        totalToken2 += _amount;
        totalToken1 -= token1AmountAfterFee;

        _updatePrice();
        emit Swap(msg.sender, token1AmountAfterFee, _amount, false);
        
    }

    function addLiquidity(uint _tokenAmount, uint256 _token2Amount) external nonReentrant {
        
    }

    function _updatePrice() internal {
        if (totalToken1 > 0 && totalToken2 > 0) {
            price = (totalToken2 * PRICE_PRECISION) / totalToken1;
            emit PriceUpdated(price);
        }
    }
}
