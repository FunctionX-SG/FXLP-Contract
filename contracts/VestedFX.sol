// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {IStakeFXVault} from "./interfaces/IStakeFXVault.sol";


contract VestedFX is Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IStakeFXVault private stakeFXVault;
    IStakeFXVault private fxFeeTreasury;

    struct VestingSchedule {
        uint64 startTime;
        uint64 endTime;
        uint256 quantity;
        uint256 vestedQuantity;
    }

    struct VestingSchedules {
        uint256 length;
        mapping(uint256 => VestingSchedule) data;
    }

    /// @dev vesting schedule of an account
    mapping(address => VestingSchedules) private accountVestingSchedules;

    /// @dev An account's total escrowed balance per token to save recomputing this for fee extraction purposes
    mapping(address => uint256) public accountEscrowedBalance;

    /// @dev An account's total vested swap per token
    mapping(address => uint256) public accountVestedBalance;

    /* ========== EVENTS ========== */
    event VestingEntryCreated(address indexed beneficiary, uint256 startTime, uint256 endTime, uint256 quantity, uint256 index);
    event Vested(address indexed beneficiary, uint256 vestedQuantity, uint256 index);

    receive() external payable {}

    /* ========== MODIFIERS ========== */
    modifier onlyStakeFX() {
        require(msg.sender == address(stakeFXVault), "Only stakeFX can call");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /****************************************** Core Functions ******************************************/
    /**
    * @dev Allow a user to vest all ended schedules
    */
    function vestCompletedSchedules() public nonReentrant returns (uint256) {
        uint256 totalVesting = 0;
        totalVesting = _vestCompletedSchedules();

        return totalVesting;
    }

    function vestScheduleAtIndices(uint256[] memory indexes) public nonReentrant returns (uint256) {
        VestingSchedules storage schedules = accountVestingSchedules[msg.sender];
        uint256 schedulesLength = schedules.length;
        uint256 totalVesting = 0;
        for (uint256 i = 0; i < indexes.length; i++) {
            require(indexes[i] < schedulesLength, 'invalid schedule index');
            VestingSchedule memory schedule = schedules.data[indexes[i]];
            uint256 vestQuantity = _getVestingQuantity(schedule);
            if (vestQuantity == 0) {
            continue;
            }
            schedules.data[indexes[i]].vestedQuantity = (schedule.vestedQuantity) + (vestQuantity);

            totalVesting = totalVesting + (vestQuantity);

            emit Vested(msg.sender, vestQuantity, indexes[i]);
        }
        _completeVesting(totalVesting);
        return totalVesting;
    }

    /**************************************** View Functions ****************************************/
    /**
    * @notice The number of vesting dates in an account's schedule.
    */
    function numVestingSchedules(address account) external view returns (uint256) {
        return accountVestingSchedules[account].length;
    }

    /**
    * @dev manually get vesting schedule at index
    */
    function getVestingScheduleAtIndex(address account, uint256 index) external view returns (VestingSchedule memory) {
        return accountVestingSchedules[account].data[index];
    }

    /**
    * @dev Get all schedules for an account.
    */
    function getVestingSchedules(address account) external view returns (VestingSchedule[] memory schedules) {
        uint256 schedulesLength = accountVestingSchedules[account].length;
        schedules = new VestingSchedule[](schedulesLength);
        for (uint256 i = 0; i < schedulesLength; i++) {
            schedules[i] = accountVestingSchedules[account].data[i];
        }
    }

    function getstakeFXVault() external view returns (address) {
        return address(stakeFXVault);
    }

    function getFxFeeTreasury() external view returns (address) {
        return address(fxFeeTreasury);
    }

    /* ==================== INTERNAL FUNCTIONS ==================== */
    /**
    * @dev Allow a user to vest all ended schedules
    */
    function _vestCompletedSchedules() internal returns (uint256) {
        VestingSchedules storage schedules = accountVestingSchedules[msg.sender];
        uint256 schedulesLength = schedules.length;

        uint256 totalVesting = 0;
        for (uint256 i = 0; i < schedulesLength; i++) {
            VestingSchedule memory schedule = schedules.data[i];
            if (_getBlockTime() < schedule.endTime) {
            continue;
            }
            uint256 vestQuantity = (schedule.quantity) - (schedule.vestedQuantity);
            if (vestQuantity == 0) {
            continue;
            }
            schedules.data[i].vestedQuantity = schedule.quantity;
            totalVesting = totalVesting + (vestQuantity);

            emit Vested(msg.sender, vestQuantity, i);
        }
        _completeVesting(totalVesting);

        return totalVesting;
    }

    function _completeVesting(uint256 totalVesting) internal {
        require(totalVesting != 0, '0 vesting amount');

        accountEscrowedBalance[msg.sender] = accountEscrowedBalance[msg.sender] - (totalVesting);
        accountVestedBalance[msg.sender] = accountVestedBalance[msg.sender] + (totalVesting);

        uint256 liquidity = address(stakeFXVault).balance;

        if(liquidity < totalVesting) {
             uint256 feesTreasuryLiquidity = address(fxFeeTreasury).balance;
             require((liquidity + feesTreasuryLiquidity) >= totalVesting, "Insuffient liq");
             fxFeeTreasury.sendVestedFX(totalVesting - liquidity);
             stakeFXVault.sendVestedFX(liquidity);
        } else {
            stakeFXVault.sendVestedFX(totalVesting);
        }
        address recipient = payable(msg.sender);
        (bool success, ) = recipient.call{value: totalVesting}("");
        require(success, "Failed to send FX");
    }

    /**
    * @dev implements linear vesting mechanism
    */
    function _getVestingQuantity(VestingSchedule memory schedule) internal view returns (uint256) {
        if (_getBlockTime() >= uint256(schedule.endTime)) {
            return (schedule.quantity) - (schedule.vestedQuantity);
        }
        if (_getBlockTime() <= uint256(schedule.startTime)) {
            return 0;
        }
        uint256 lockDuration = uint256(schedule.endTime) - (schedule.startTime);
        uint256 passedDuration = _getBlockTime() - uint256(schedule.startTime);
        return (passedDuration*(schedule.quantity)/(lockDuration)) - (schedule.vestedQuantity);
    }

    /**
    * @dev wrap block.timestamp so we can easily mock it
    */
    function _getBlockTime() internal virtual view returns (uint32) {
        return uint32(block.timestamp);
    }


    /**************************************** Only Authorised Functions ****************************************/

    function lockWithEndTime(address account, uint256 quantity, uint256 endTime) external onlyStakeFX {
        require(quantity > 0, '0 quantity');

        VestingSchedules storage schedules = accountVestingSchedules[account];
        uint256 schedulesLength = schedules.length;

        // append new schedule
        schedules.data[schedulesLength] = VestingSchedule({
            startTime: uint64(block.timestamp),
            endTime: uint64(endTime),
            quantity: quantity,
            vestedQuantity: 0
        });
        schedules.length = schedulesLength + 1;
        // record total vesting balance of user
        accountEscrowedBalance[account] = accountEscrowedBalance[account] + (quantity);

        emit VestingEntryCreated(account, block.timestamp, endTime, quantity, schedulesLength);
    }

    function recoverToken(address token, uint256 amount, address recipient) external onlyOwner nonReentrant{
        require(recipient != address(0), "Send to zero address");
        IERC20Upgradeable(token).safeTransfer(recipient, amount);
    }

    function updateStakeFXVault(address _stakeFXVault) external onlyOwner nonReentrant{
        stakeFXVault = IStakeFXVault(_stakeFXVault);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**************************************************************
     * @dev Initialize the states
     *************************************************************/

    function initialize(address _stakeFXVault) public initializer {
        stakeFXVault = IStakeFXVault(_stakeFXVault);

        __Ownable_init();
        __UUPSUpgradeable_init();
    }

}