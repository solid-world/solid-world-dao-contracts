// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/rewards/IEACAggregatorProxy.sol";

library RewardsDataTypes {
    struct RewardsConfigInput {
        uint88 emissionPerSecond;
        uint256 totalStaked;
        uint32 distributionEnd;
        address asset; // hypervisor
        address reward; // CBT, USDC, Governance token
        IEACAggregatorProxy rewardOracle;
    }

    struct UserAssetBalance {
        address asset;
        uint256 userStake;
        uint256 totalStaked;
    }

    struct UserData {
        uint104 index;
        uint128 accrued;
    }

    struct RewardData {
        uint104 index;
        uint88 emissionPerSecond;
        uint32 lastUpdateTimestamp;
        uint32 distributionEnd;
        mapping(address => UserData) usersData;
    }

    struct AssetData {
        mapping(address => RewardData) rewards;
        mapping(uint128 => address) availableRewards;
        uint128 availableRewardsCount;
        uint8 decimals;
    }
}
