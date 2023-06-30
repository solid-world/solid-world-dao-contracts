// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

enum RouterBehaviour {
    MINTS_TOKEN0,
    MINTS_TOKEN1,
    REVERTS_NO_REASON,
    REVERTS_WITH_REASON,
    GAS_INTENSIVE
}
