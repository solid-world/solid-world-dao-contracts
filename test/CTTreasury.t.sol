// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";

import "../contracts/CTTreasury.sol";
import "../contracts/SolidDaoManagement.sol";
import "../contracts/tokens/ERC1155-flat.sol";
import "../contracts/CTERC20.sol";


contract ERC1155ReceiverTest is IERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return true;
    }
}

contract CTTreasuryTest is Test, ERC1155ReceiverTest {
    SolidDaoManagement private authority;
    CarbonCredit private projectToken;
    CTERC20TokenTemplate private carbonToken;
    CTTreasury private treasury;

    address root = address(this);
    uint256 constant public ONE_WEEK = 604800;
    uint256 constant public ONE_YEAR = 604800 * 52;
    address internal daoTreasuryAddress = vm.addr(1);

    function setUp() public {
        // Changing current date is required in order to pass through "SolidMath.weeksInThePeriod",
        // since block.timestamp in forge is equal to 1.
        vm.warp(ONE_WEEK);

        authority = new SolidDaoManagement(root, root, root, root);
        carbonToken = new CTERC20TokenTemplate('Dummy Carbon Token', 'DCT');
        treasury = new CTTreasury({
            _authority: address(authority),
            _ct: address(carbonToken),
            _timelock: 0,
            _category: 'foo',
            _daoTreasury: daoTreasuryAddress,
            _daoLiquidityFee: 2 // 2%
        });
        treasury.initialize();
        carbonToken.initialize(address(treasury));

        treasury.permissionToDisableTimelock();
        treasury.disableTimelock();
        treasury.enable(CTTreasury.STATUS.RESERVEMANAGER, root);

        projectToken = new CarbonCredit();
        projectToken.initialize("");
        projectToken.setApprovalForAll(address(treasury), true);
    }

    function testDeposit_TransferProjectTokensToTreasury() public {
        _createProject(3, block.timestamp + ONE_YEAR, 0);

        assertEq(projectToken.balanceOf(root, 3), 19000);
        assertEq(projectToken.balanceOf(address(treasury), 3), 0);

        treasury.depositReserveToken({
            _token: address(projectToken),
            _tokenId: 3,
            _amount: 300,
            _owner: root
        });

        assertEq(projectToken.balanceOf(root, 3), 18700);
        assertEq(projectToken.balanceOf(address(treasury), 3), 300);
    }

    function testDeposit_MintCarbonTokens() public {
        _createProject(3, block.timestamp + ONE_WEEK, 984);

        assertEq(carbonToken.balanceOf(root), 0);
        assertEq(carbonToken.balanceOf(daoTreasuryAddress), 0);

        treasury.depositReserveToken({
            _token: address(projectToken),
            _tokenId: 3,
            _amount: 10000,
            _owner: root
        });

        assertEq(carbonToken.balanceOf(root), 9790_356800000_000000000);
        assertEq(carbonToken.balanceOf(daoTreasuryAddress), 199_803200000_000000000);
    }

    function _createProject(uint128 tokenId, uint256 dueDate, uint discountRate) private {
        CTTreasury.CarbonProject memory carbonProject = CTTreasury.CarbonProject({
            token: address(projectToken),
            tokenId: tokenId,
            tons: 100,
            contractExpectedDueDate: dueDate,
            projectDiscountRate: discountRate,
            isActive: true,
            isCertified: false,
            isRedeemed: false
        });
        treasury.enable(CTTreasury.STATUS.RESERVETOKEN, carbonProject.token);
        treasury.createOrUpdateCarbonProject(carbonProject);

        projectToken.mint({ _to: root, _id: tokenId, _amount: 19000, _data: ""});
    }

    function testPayout() public {
        // Payout for 1st week
        (, uint256 userAmountOut1, uint256 daoAmountOut1) = treasury.payout(1, 10000, 984, 2, 18);
        assertEq(userAmountOut1, 9790_356800000_000000000);
        assertEq(daoAmountOut1, 199_803200000_000000000);

        // Payout after 1 year
        (, uint256 userAmountOut2, uint256 daoAmountOut2) = treasury.payout(52, 10000, 984, 2, 18);
        assertEq(userAmountOut2, 9310_666400000_000000000);
        assertEq(daoAmountOut2, 190_013600000_000000000);

        // Payout after 10 years
        (, uint256 userAmountOut3, uint256 daoAmountOut3) = treasury.payout(520, 100000, 984, 2, 18);
        assertEq(userAmountOut3, 58714_348000000_000000000);
        assertEq(daoAmountOut3, 1198_252000000_000000000);
    }

}
