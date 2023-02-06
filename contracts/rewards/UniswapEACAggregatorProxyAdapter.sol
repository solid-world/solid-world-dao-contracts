// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

import "../interfaces/rewards/IEACAggregatorProxy.sol";

/// @notice minimal interface for computing decimals of a token
/// @dev not importing from OpenZeppelin because of solc version mismatch
interface IERC20 {
    function decimals() external view returns (uint8);
}

/// @notice minimal implementation of an Ownable contract
/// @dev not importing from OpenZeppelin because of solc version mismatch
abstract contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "INVALID_OWNER");
        owner = newOwner;
    }
}

/// @title Adapter from Uniswap V3 Oracle to Chainlink EACAggregatorProxy
/// @notice This contract exposes a method for getting the price of a token from the Uniswap V3 Pool
/// and converting it to a format that is compatible with the Chainlink EACAggregatorProxy interface.
/// @author Solid World DAO
contract UniswapEACAggregatorProxyAdapter is IEACAggregatorProxy, Ownable {
    address public immutable baseToken;
    address public immutable quoteToken;
    address public immutable pool;

    /// @notice the number of seconds in the past from which to calculate the time-weighted means
    uint32 public secondsAgo;

    constructor(
        address _owner,
        address factory,
        address _baseToken,
        address _quoteToken,
        uint24 _fee,
        uint32 _secondsAgo
    ) {
        transferOwnership(_owner);

        baseToken = _baseToken;
        quoteToken = _quoteToken;
        secondsAgo = _secondsAgo;

        address _pool = IUniswapV3Factory(factory).getPool(_baseToken, _quoteToken, _fee);
        require(_pool != address(0), "INVALID_POOL_PARAMS");

        pool = _pool;
    }

    function setSecondsAgo(uint32 _secondsAgo) external onlyOwner {
        secondsAgo = _secondsAgo;
    }

    function latestAnswer() external view override returns (int) {
        uint price = _computePrice();

        return int(price); // will not overflow
    }

    /// @dev decimals of the quote token
    function decimals() external view override returns (uint8) {
        return IERC20(quoteToken).decimals();
    }

    /// @return price Amount of quoteToken received for 1 unit of baseToken
    function _computePrice() internal view returns (uint price) {
        (int24 tick, ) = OracleLibrary.consult(pool, secondsAgo);

        uint128 baseTokenUnit = uint128(10**IERC20(baseToken).decimals());

        price = OracleLibrary.getQuoteAtTick(tick, baseTokenUnit, baseToken, quoteToken);
    }
}
