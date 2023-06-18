// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// import "../libraries/math/SafeMath.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./interfaces/IRewardDistributor.sol";
import "./interfaces/IStakeFXVault.sol";
import "./common/Governable.sol";

contract RewardDistributor is Initializable, UUPSUpgradeable, IRewardDistributor, ReentrancyGuardUpgradeable, Governable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public override rewardToken;
    uint256 public override tokensPerInterval;
    uint256 public lastDistributionTime;
    address public rewardTracker;

    address public admin;

    event Distribute(uint256 amount);
    event TokensPerIntervalChange(uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "RewardDistributor: forbidden");
        _;
    }

    function setAdmin(address _admin) external onlyRole(OWNER_ROLE) {
        admin = _admin;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external onlyRole(OWNER_ROLE) {
        IERC20Upgradeable(_token).safeTransfer(_account, _amount);
    }

    function updateLastDistributionTime() external onlyAdmin {
        lastDistributionTime = block.timestamp;
    }

    function setTokensPerInterval(uint256 _amount) external onlyRole(GOVERNOR_ROLE) {
        require(lastDistributionTime != 0, "RewardDistributor: invalid lastDistributionTime");
        IStakeFXVault(rewardTracker).updateRewards();
        tokensPerInterval = _amount;
        emit TokensPerIntervalChange(_amount);
    }

    function pendingRewards() public view override returns (uint256) {
        if (block.timestamp == lastDistributionTime) {
            return 0;
        }

        uint256 timeDiff = block.timestamp.sub(lastDistributionTime);
        return tokensPerInterval.mul(timeDiff);
    }

    function distribute() external override returns (uint256) {
        require(msg.sender == rewardTracker, "RewardDistributor: invalid msg.sender");
        uint256 amount = pendingRewards();
        if (amount == 0) { return 0; }

        lastDistributionTime = block.timestamp;

        uint256 balance = IERC20Upgradeable(rewardToken).balanceOf(address(this));
        if (amount > balance) { amount = balance; }

        IERC20Upgradeable(rewardToken).safeTransfer(msg.sender, amount);

        emit Distribute(amount);
        return amount;
    }

    function _authorizeUpgrade(
        address
    ) internal override onlyRole(OWNER_ROLE) {} 

    /**************************************************************
     * @dev Initialize the states
     *************************************************************/
    // constructor() public {

    // }
    
    function initialize(
        address _rewardToken, address _rewardTracker, address _owner, address _governor
    ) public initializer {
        rewardToken = _rewardToken;
        rewardTracker = _rewardTracker;
        admin = msg.sender;
        
        __Governable_init(_owner, _governor);
        __UUPSUpgradeable_init();
    }
}