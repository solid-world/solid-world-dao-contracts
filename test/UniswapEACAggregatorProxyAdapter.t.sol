// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma abicoder v2;

import "forge-std/Test.sol";
import "../contracts/rewards/UniswapEACAggregatorProxyAdapter.sol";

contract UniswapEACAggregatorProxyAdapterTest is Test {
    UniswapEACAggregatorProxyAdapter adapter;

    address root = address(this);
    address testAccount = vm.addr(1);
    address baseToken = vm.addr(2);
    address quoteToken = vm.addr(3);
    address poolFactory = vm.addr(4);
    address pool = vm.addr(5);
    address owner = vm.addr(6);

    uint24 fee = 1000;
    uint32 secondsAgo = 5 minutes;

    function setUp() public {
        vm.mockCall(
            poolFactory,
            abi.encodeWithSignature("getPool(address,address,uint24)", baseToken, quoteToken, fee),
            abi.encode(pool)
        );
        adapter = new UniswapEACAggregatorProxyAdapter(
            owner,
            poolFactory,
            baseToken,
            quoteToken,
            fee,
            secondsAgo
        );

        assertEq(adapter.pool(), pool, "Pool should be set");
        assertEq(adapter.owner(), owner, "Owner should be set");

        vm.label(root, "Root account");
        vm.label(testAccount, "Test account");
        vm.label(baseToken, "Base token");
        vm.label(quoteToken, "Quote token");
        vm.label(poolFactory, "Pool factory");
        vm.label(pool, "Pool");
        vm.label(owner, "Owner");
    }

    function testSetSecondsAgo() public {
        uint32 newSecondsAgo = 10 minutes;

        vm.prank(owner);
        adapter.setSecondsAgo(newSecondsAgo);

        assertEq(uint(adapter.secondsAgo()), uint(newSecondsAgo), "Seconds ago should be set");

        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        adapter.setSecondsAgo(newSecondsAgo);
    }

    function testDecimals() public {
        vm.mockCall(quoteToken, abi.encodeWithSignature("decimals()"), abi.encode(uint8(7)));
        assertEq(uint(adapter.decimals()), uint(7), "Decimals should be 7");
    }

    function testLatestAnswer() public {
        uint32[] memory secondAgos = new uint32[](2);
        secondAgos[0] = 300;
        secondAgos[1] = 0;

        int56[] memory tickCumulatives = new int56[](2);
        tickCumulatives[0] = 0;
        tickCumulatives[1] = 300;

        uint160[] memory secondsPerLiquidityCumulativeX128s = new uint160[](2);
        secondsPerLiquidityCumulativeX128s[0] = 100;
        secondsPerLiquidityCumulativeX128s[1] = 200;

        vm.mockCall(
            pool,
            abi.encodeWithSignature("observe(uint32[])", secondAgos),
            abi.encode(tickCumulatives, secondsPerLiquidityCumulativeX128s)
        );
        vm.mockCall(baseToken, abi.encodeWithSignature("decimals()"), abi.encode(uint8(18)));
        int answer = adapter.latestAnswer();

        assertEq(uint(answer), uint(1000100000000000000), "Answer should be 1000100000000000000");
    }
}
