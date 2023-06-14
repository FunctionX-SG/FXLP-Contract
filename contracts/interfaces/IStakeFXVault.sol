// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IFXDelegateCmpoundStrategy {
    /**
     * @notice Return the amount of GLP that represent 1x of leverage
     * @return Amount of GLP
     */
    function getUnderlyingFX() external view returns (uint256);

    function sendVestedFX(uint256 safeAmount) external;

    function stake() external payable;

    function unstake(uint256 amount) external;

    function entrustDelegatedShare(string memory val, uint256 amount) external;

    function compound() external;

    function addValidator(string memory val, uint256 newAllocPoint) external;
}