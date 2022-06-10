// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./IERC20.sol";

interface ICT is IERC20 {
  function mint(address account_, uint256 amount_) external;

  function burn(uint256 amount) external;

  function burnFrom(address account_, uint256 amount_) external;
}
