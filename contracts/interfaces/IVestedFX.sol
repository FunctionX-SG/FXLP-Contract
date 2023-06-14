// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IVestedFX {
    function lockWithEndTime(address account, uint256 quantity, uint256 endTime) external;
}