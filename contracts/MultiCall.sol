// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.18;

// import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
// import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
// import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
// import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// import {IVestedFX} from "./interfaces/IVestedFX.sol";
// import {IRewardDistributor} from "./interfaces/IRewardDistributor.sol";
// import {IWFX} from "./interfaces/IWFX.sol";
// import {IStakeFXVault} from "./interfaces/IStakeFXVault.sol";
// import {PrecompileStaking} from "./imp/PrecompileStaking.sol";

// contract MultiCall is
//     Initializable,
//     UUPSUpgradeable,
//     PrecompileStaking
// {
//     using SafeERC20Upgradeable for IERC20Upgradeable;
//     using MathUpgradeable for uint256;

//     uint256 internal constant BIPS_DIVISOR = 10000;
//     uint256 internal constant PRECISION = 1e30;

//     address public vestedFX;                    // Contract that stored user's withdrawal info
//     address public feeTreasury;                 // Contract that keep compound reward fee
//     address public stakeFXVault;                 // Reward token distributor

//     // Newly added storage
//     address constant WFX = 0x3452e23F9c4cC62c70B7ADAd699B264AF3549C19;  // WFX mainnet 0x80b5a32E4F032B2a058b4F29EC95EEfEEB87aDcd

//     struct VaultInfo {
//         uint256 stakeId;
//         uint256 unstakeId;
//         uint256 length;        
//         uint256 totalAllocPoint;
//         uint256 cumulativeRewardPerToken;
//     }

//     struct ValInfo {
//         uint256 allocPoint;
//         string validator;
//     }

//     struct UserInfo {
//         uint256 claimableReward;
//         uint256 previousCumulatedRewardPerToken;
//     }

//     event Stake(address indexed user, uint256 amount, uint256 shares);
//     event Unstake(address indexed user, uint256 amount, uint256 shares);
//     event Compound(address indexed user, uint256 compoundAmount);
//     event Claim(address receiver, uint256 amount);
//     event ValidatorAdded(string val, uint256 newAllocPoint);
//     event ValidatorRemoved(string val);
//     event ValidatorUpdated(string val, uint256 newAllocPoint);
//     event VestedFXChanged(address newAddress);
//     event FeeTreasuryChanged(address newAddress);
//     event DistributorChanged(address newAddress);

//     /// @custom:oz-upgrades-unsafe-allow constructor
//     constructor() {
//         _disableInitializers();
//     }

//     // function _authorizeUpgrade(
//     //     address
//     // ) internal override onlyRole(OWNER_ROLE) {} 


//     /**************************************** Public/External View Functions ****************************************/

//     /**
//      * @notice Return total asset(FX) deposited
//      * @return Amount of asset(FX) deposited
//      */
//     function totalAssets() public view override returns (uint256) {
//         uint256 underlying = _getUnderlyingFX();
//         return underlying;
//     }

//     function getValLength() public view returns (uint256) {
//         return vaultInfo.length;
//     }

//     /**
//      * @notice Return delegation share and fx amount
//      */
//     function getDelegationInfo(
//         uint256 index
//     ) external view returns (uint256, uint256) {
//         (uint256 sharesAmount, uint256 delegationAmount) = _delegation(valInfo[index].validator, address(this));
//         return (sharesAmount, delegationAmount);
//     }

//     function getVaultDelegationInfo(
//         uint256 index
//     ) external view returns (uint256, uint256) {
//         (uint256 sharesAmount, uint256 delegationAmount) = _delegation(valInfo[index].validator, address(this));
//         return (sharesAmount, delegationAmount);
//     }    

//     /**
//      * @notice Return validator address and allocPoint
//      */
//     function getValInfo(uint256 index) public view returns (uint256, string memory) {
//         return (valInfo[index].allocPoint, valInfo[index].validator);
//     }

//     /**
//      * @notice Return total delegation reward
//      */
//     function getTotalDelegationRewards() public view returns (uint256) {
//         uint256 totalAmount;
//         uint256 valLength = getValLength();
//         for (uint256 i; i < valLength; i++) {
//             string memory validator = valInfo[i].validator;
//             uint256 delegationReward = _delegationRewards(validator, address(this));
//             totalAmount += delegationReward;
//         }
//         return totalAmount + pendingFxReward;
//     }

//     function getVaultConfigs() public view returns (uint256, uint256, uint256, uint256) {
//         return (MIN_COMPOUND_AMOUNT, CAP_STAKE_FX_TARGET, UNSTAKE_FX_TARGET, STAKE_FX_TARGET);
//     }

//     function rewardToken() public view returns (address) {
//         return IRewardDistributor(distributor).rewardToken();
//     }

//     function claimable(address account) public view returns (uint256) {
//         UserInfo memory user = userInfo[account];
//         uint256 stakedAmount = balanceOf(account);
//         if (stakedAmount == 0) {
//             return user.claimableReward;
//         }
//         uint256 supply = totalSupply();
//         uint256 pendingRewards = IRewardDistributor(distributor).pendingRewards() * (PRECISION);
//         uint256 nextCumulativeRewardPerToken = vaultInfo.cumulativeRewardPerToken + (pendingRewards / (supply));
//         return user.claimableReward + (
//             stakedAmount * (nextCumulativeRewardPerToken - (user.previousCumulatedRewardPerToken)) / (PRECISION));
//     }

    

//     /**************************************** Only Owner Functions ****************************************/

//     function recoverToken(
//         address token,
//         uint256 amount,
//         address _recipient
//     ) external onlyRole(OWNER_ROLE) {
//         require(_recipient != address(0), "Send to zero address");
//         IERC20Upgradeable(token).safeTransfer(_recipient, amount);
//     }


//     /**************************************************************
//      * @dev Initialize the states
//      *************************************************************/

//     function initialize(
//         address _asset,
//         address _owner,
//         address _governor
//     ) public initializer {
//         __BaseVaultInit(
//             _asset,
//             "Staked FX Token",
//             "StFX",
//             _owner,
//             _governor
//         );
//         __Governable_init(_owner, _governor);
//         __UUPSUpgradeable_init();
//     }
// }