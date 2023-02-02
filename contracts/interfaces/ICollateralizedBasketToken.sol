// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface ICollateralizedBasketToken is IERC20Metadata {
    function mint(address account_, uint amount_) external;

    function burn(uint amount) external;

    function burnFrom(address account_, uint amount_) external;
}
