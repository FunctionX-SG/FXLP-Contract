// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IStakeFXVault {

    function sendVestedFX(uint256 safeAmount) external;

    function updateRewards() external;
}
