// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "../interfaces/rewards/IEACAggregatorProxy.sol";

library RewardsDataTypes {
    struct DistributionConfig {
        uint88 emissionPerSecond;
        uint totalStaked;
        uint32 distributionEnd;
        address asset;
        address reward;
        IEACAggregatorProxy rewardOracle;
    }

    struct AssetStakedAmounts {
        address asset;
        uint userStake;
        uint totalStaked;
    }

    struct AssetData {
        mapping(address => RewardDistribution) rewardDistribution;
        mapping(uint128 => address) availableRewards;
        uint128 availableRewardsCount;
        uint8 decimals;
    }

    struct RewardDistribution {
        uint104 index;
        uint88 emissionPerSecond;
        uint32 lastUpdateTimestamp;
        uint32 distributionEnd;
        mapping(address => UserData) usersData;
    }

    struct UserData {
        uint104 index;
        uint128 accrued;
    }
}
