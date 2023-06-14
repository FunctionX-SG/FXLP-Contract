// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IFXDelegateCmpoundStrategy {
    /**
     * @notice Return the amount of GLP that represent 1x of leverage
     * @return Amount of GLP
     */
    function getUnderlyingFX() external view returns (uint256);

    function sendVestedFX(uint256 safeAmount) external;
}
