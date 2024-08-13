// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IStakeFXVault {

    function sendVestedFX(uint256 safeAmount) external;

    function updateRewards() external;

    function getValLength() external view returns (uint256);

    function getValInfo(uint256 index) external view returns (uint256, string memory);

    function stake(uint256 amount, bool native) external payable;

    function unstake(uint256 amount) external;

    function entrustDelegatedShare(string memory val, uint256 amount) external;

    function compound() external;

    function claim(address receiver) external returns (uint256);
}
