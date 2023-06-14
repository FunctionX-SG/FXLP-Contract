// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {IVestedFX} from "./interfaces/IVestedFX.sol";
import {BaseVault} from "./vaults/BaseVault.sol";
import {PrecompileStaking} from "./imp/PrecompileStaking.sol";

contract StakeFXVault is
    Initializable,
    UUPSUpgradeable,
    PrecompileStaking,
    ReentrancyGuardUpgradeable,
    BaseVault
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using MathUpgradeable for uint256;

    uint256 internal constant BIPS_DIVISOR = 10000;

    uint256 public pendingFxReward;             // FX rewards in the contract
    uint256 public feeOnReward;
    uint256 public feeOnWithdrawal;
    address public vestedFX;
    address public feeTreasury;

    uint256 private MIN_COMPOUND_AMOUNT;
    uint256 private CAP_STAKE_FX_TARGET; 
    uint256 private UNSTAKE_FX_TARGET;
    uint256 private STAKE_FX_TARGET;
    
    VaultInfo public vaultInfo;
    mapping(uint256 => ValInfo) public valInfo;

    struct VaultInfo {
        uint256 stakeId;
        uint256 unstakeId;
        uint256 length;        
        uint256 totalAllocPoint;
    }

    struct ValInfo {
        uint256 allocPoint;
        string validator;
    }

    event Stake(address indexed user, uint256 amount, uint256 shares);
    event Unstake(address indexed user, uint256 amount, uint256 shares);
    event ValidatorUpdated(string val, uint256 newAllocPoint);
    event ValidatorAdded(string val, uint256 newAllocPoint);
    event Compound(address indexed user, uint256 fees, uint256 compoundAmount);
    event VestedFXChanged(address newAddress);
    event FeeTreasuryChanged(address newAddress);

    modifier onlyVestedFX() {
        require(msg.sender == vestedFX, "Only VestedFX can call");
        _;
    }

    /****************************************** Core Functions ******************************************/
    /**
     * @notice user stake FX to this contract
     */
    function stake() external payable {
        require(msg.value > 0, "Stake: 0 amount");
        uint256 totalAsset = totalAssets();
        require(msg.value + totalAsset <= CAP_STAKE_FX_TARGET, "Stake: > Cap");

        uint256 delegationReward = getTotalDelegationRewards();
        if(delegationReward >= MIN_COMPOUND_AMOUNT) {
            compound();
        }
        
        uint256 shares = previewDeposit(msg.value);
        _mint(msg.sender, shares);

        _stake(msg.value);

        emit Stake(msg.sender, msg.value, shares);
    }

    /**
     * @notice transfer user delegate share to this contract
     * @param amount User's fx-LP receipt tokens
     */
    function unstake(uint256 amount) external {
        require(amount > 0, "Unstake: 0 amount");

        uint256 sharesBalance = balanceOf(msg.sender);
        require(sharesBalance >= amount, "Amount > stake");

        uint256 undelegateAmount = previewRedeem(amount);
        uint256 undelegateAmountAfterFee = undelegateAmount * (BIPS_DIVISOR - feeOnWithdrawal) / BIPS_DIVISOR;

        _burn(msg.sender, amount);
        
        _unstake(undelegateAmountAfterFee);
     
        emit Unstake(msg.sender, undelegateAmountAfterFee, amount);
    }

    /**
     * @notice transfer user delegate share to this contract
     * @param val validator address
     * @param amount Amount of user's delegate shares transferred to this contract
     */
    function entrustDelegatedShare(string memory val, uint256 amount) external {
        require(amount > 0, "Entrust: 0 share");

        (uint256 shares, ) = _delegation(val, msg.sender);
        require(shares >= amount, "Not enough share");

        uint256 delegationReward = getTotalDelegationRewards();
        if(delegationReward >= MIN_COMPOUND_AMOUNT) {
            compound();
        }

        uint256 totalAsset = totalAssets();
        uint256 supply = totalSupply();

        (uint256 fxAmountToTransfer, uint256 returnRewards) = _transferFromShares(val, msg.sender, address(this), amount);

        pendingFxReward += returnRewards;

        uint256 sharesAmount = (fxAmountToTransfer == 0 || supply == 0)
                ? _initialConvertToShares(fxAmountToTransfer, MathUpgradeable.Rounding.Down)
                : fxAmountToTransfer.mulDiv(supply, totalAsset, MathUpgradeable.Rounding.Down);

        _mint(msg.sender, sharesAmount);

        emit Stake(msg.sender, fxAmountToTransfer, sharesAmount); 
    }

    function compound() public nonReentrant {
        uint256 delegateAmount = _claimReward() + pendingFxReward;
        pendingFxReward = 0;
        uint256 fees = (delegateAmount * feeOnReward) / BIPS_DIVISOR;
        delegateAmount -= fees;

        address recipient = payable(feeTreasury);
        (bool success, ) = recipient.call{value: fees}("");
        require(success, "Failed to send FX");
        
        _stake(delegateAmount);

        emit Compound(msg.sender, fees, delegateAmount);
    }

    /**************************************** Internal and Private Functions ****************************************/

    function _stake2(uint256 amount) internal {
        VaultInfo memory vault = vaultInfo;
        uint256 totalAllocPoint = vault.totalAllocPoint;
        uint256 newTotalAllocPoint = totalAllocPoint;
        uint256 totalReturnReward;
        uint256 index = vault.stakeId;
        if (amount <= STAKE_FX_TARGET) {
            uint256 numValidators = _calculateNumberofValidators(amount);
            uint256 amountPerValidator = amount / numValidators;

            while (amount != 0) {
                ValInfo memory val = valInfo[index];
                uint256 allocPoint = val.allocPoint;

                (, uint256 delegationAmount) = _delegation(val.validator, address(this));
                uint256 maxValSize = allocPoint * CAP_STAKE_FX_TARGET / totalAllocPoint;

                if (delegationAmount >= maxValSize) {
                    index = (index + 1) % vault.length;
                    continue;
                }

                uint256 delegateAmount = 0;

                if (amount < amountPerValidator) {
                    delegateAmount = amount;
                } else {
                    delegateAmount = amountPerValidator;
                }

                (, uint256 returnReward) = _delegate(val.validator, delegateAmount);
                totalReturnReward += returnReward;
                amount -= delegateAmount;
                index = (index + 1) % vault.length;
            }
        } else {
            while (amount != 0) {
                ValInfo memory val = valInfo[index];
                uint256 allocPoint = val.allocPoint;

                (, uint256 delegationAmount) = _delegation(val.validator, address(this));
                uint256 maxValSize = allocPoint * CAP_STAKE_FX_TARGET / totalAllocPoint;
                index = (index + 1) % vault.length;
                
                // Skip validators that has reach max of its allocation FX delegation
                if (delegationAmount >= maxValSize) {
                    newTotalAllocPoint -= allocPoint;                
                    continue;
                }
                
                // If newTotalAllocPoint equal to 0, it means last validator in this while loop has reach max of its FX allocation, delegate remaining FX to this loop validator.
                // If remainingAmount less than minimum compound target, delegate remaining FX to this round validator to save gas.
                uint256 delegateAmount;
                if(newTotalAllocPoint == 0) {
                    delegateAmount = amount;
                } else {
                    delegateAmount = amount * allocPoint / newTotalAllocPoint;
                    if (amount - delegateAmount <= MIN_COMPOUND_AMOUNT) {
                        delegateAmount = amount;
                    }
                    newTotalAllocPoint -= allocPoint;
                }
                
                // Skip validators that has 0 allocPoint
                if (delegateAmount == 0) {
                    continue;
                }

                uint256 returnReward;
                
                (, returnReward) = _delegate(val.validator, delegateAmount);
                totalReturnReward += returnReward;
                amount -= delegateAmount;
            }
        }

        vaultInfo.stakeId = index;
        pendingFxReward += totalReturnReward;
    }

    function _stake(uint256 amount) internal {
        VaultInfo memory vault = vaultInfo;
        uint256 totalAllocPoint = vault.totalAllocPoint;
        uint256 index = vault.stakeId;
        uint256 vaultLength = vault.length;

        uint256 totalReturnReward;

        if (amount <= STAKE_FX_TARGET) {
            uint256 numValidators = _calculateNumberofValidators(amount);
            uint256 amountPerValidator = amount / numValidators;

            while (amount != 0) {
                ValInfo memory val = valInfo[index];
                uint256 allocPoint = val.allocPoint;

                (, uint256 delegationAmount) = _delegation(val.validator, address(this));
                uint256 maxValSize = allocPoint * CAP_STAKE_FX_TARGET / totalAllocPoint;

                if (delegationAmount >= maxValSize) {
                    index = (index + 1) % vaultLength;
                    continue;
                }

                uint256 delegateAmount = 0;

                if (amount < amountPerValidator) {
                    delegateAmount = amount;
                } else {
                    delegateAmount = amountPerValidator;
                }

                (, uint256 returnReward) = _delegate(val.validator, delegateAmount);
                totalReturnReward += returnReward;
                amount -= delegateAmount;
                index = (index + 1) % vaultLength;
            }
        } else {
            uint256 newAmount = amount;
            while (newAmount != 0) {
                ValInfo memory val = valInfo[index];
                uint256 allocPoint = val.allocPoint;

                (, uint256 delegationAmount) = _delegation(val.validator, address(this));
                uint256 maxValSize = allocPoint * CAP_STAKE_FX_TARGET / totalAllocPoint;
                index = (index + 1) % vaultLength;
                
                // Skip validators that has reach max of its allocation FX delegation
                if (delegationAmount >= maxValSize) {              
                    continue;
                }
                
                // If remainingAmount less than minimum compound target, delegate remaining FX to this round validator to save gas.
                uint256 delegateAmount = amount * allocPoint / totalAllocPoint;
                if (newAmount - delegateAmount <= MIN_COMPOUND_AMOUNT) {
                    delegateAmount = newAmount;
                }                
                
                // Skip validators that has 0 or close to 0 allocPoint
                if (delegateAmount == 0) {
                    continue;
                }

                uint256 returnReward;
                
                (, returnReward) = _delegate(val.validator, delegateAmount);
                totalReturnReward += returnReward;
                newAmount -= delegateAmount;
            }
        }

        vaultInfo.stakeId = index;
        pendingFxReward += totalReturnReward;
    }


    /**
     * @param amount Amount is in FX token
     */
    function _unstake(uint256 amount) internal {
        VaultInfo memory vault = vaultInfo;
        uint256 index = vault.unstakeId;
        uint256 vaultLength = vault.length;

        uint256 remainingAmount = amount;
        uint256 totalReward;        
        
        uint256 returnUndelegateAmount;
        uint256 returnReward;
        uint256 endTime;
        
        if (amount >= UNSTAKE_FX_TARGET) {
            uint256 halfOfUndelegateAmount = amount / 2; 
            (returnUndelegateAmount, returnReward, endTime) = _toUndelegate(index, halfOfUndelegateAmount);
                
            remainingAmount -= returnUndelegateAmount;
            index = (index + 1) % vaultLength;
            totalReward += returnReward;
            endTime = endTime;
        }

        while (remainingAmount != 0) {
            (returnUndelegateAmount, returnReward, endTime) = _toUndelegate(index, remainingAmount);
            
            remainingAmount -= returnUndelegateAmount;
            index = (index + 1) % vaultLength;
            totalReward += returnReward;
            endTime = endTime;
        }

        IVestedFX(vestedFX).lockWithEndTime(
            msg.sender,            
            amount,
            endTime
        );

        vaultInfo.unstakeId = index;
        pendingFxReward += totalReward;
    }

    function _toUndelegate(uint256 index, uint256 remainingAmount) internal returns(uint256, uint256, uint256) {
        (uint256 share, uint256 delegationAmount) = _delegation(valInfo[index].validator, address(this));

        uint256 amountToUndelegate;
        uint256 returnReward;
        uint256 endTime;

        if (delegationAmount > 0) {
            if (delegationAmount >= remainingAmount) {
                amountToUndelegate = remainingAmount;
            } else {
                amountToUndelegate = delegationAmount;
            }

            uint256 shareToWithdraw = (share * amountToUndelegate) / delegationAmount;
            (amountToUndelegate, returnReward, endTime) = _undelegate(valInfo[index].validator, shareToWithdraw);
        }

        return (amountToUndelegate, returnReward, endTime);
    }

    function _claimReward() internal returns (uint256) {
        VaultInfo memory vault = vaultInfo;
        uint256 claimedReward = 0;
        
        uint256 vaultLength = vault.length;

        for (uint256 i; i < vaultLength; i++) {
            string memory validator = valInfo[i].validator;
            uint256 delegationReward = _delegationRewards(validator, address(this));
            if(delegationReward > 0) {
                uint256 returnReward = _withdraw(validator);
                claimedReward += returnReward;
            }
        }

        return claimedReward;
    }

    function _calculateNumberofValidators(
        uint256 delegateAmount
    ) internal view returns (uint256) {
        uint256 numValidators;
        uint256 delegateAmountInEther = delegateAmount / 10**18;

        uint256 valLength = getValLength();
        while (delegateAmountInEther != 0) {
            delegateAmountInEther /= 10;
            numValidators++;
        }

        return (numValidators == 0) ? 1 : (numValidators > valLength
                ? valLength
                : numValidators);
    }

    function getUnderlyingFX() internal view returns (uint256) {
        uint256 totalAmount;
        uint256 valLength = getValLength();
        for (uint256 i; i < valLength; i++) {
            string memory validator = valInfo[i].validator;
            (, uint256 delegationAmount) = _delegation(validator, address(this));
            totalAmount += delegationAmount;
        }
        return totalAmount;
    }

    /**************************************** Public/External View Functions ****************************************/

    function getValLength() public view returns (uint256) {
        return vaultInfo.length;
    }

    function getDelegationInfo(
        uint256 index
    ) external view returns (string memory, uint256) {
        return (valInfo[index].validator, valInfo[index].allocPoint);
    }

    function getValInfo(uint256 i) public view returns (uint256, string memory) {
        return (valInfo[i].allocPoint, valInfo[i].validator);
    }

    /**
     * @notice Return total asset deposited
     * @return Amount of asset deposited
     */
    function totalAssets() public view override returns (uint256) {
        uint256 underlying = getUnderlyingFX();
        return underlying;
    }

    function getTotalDelegationRewards() public view returns (uint256) {
        uint256 totalAmount;
        uint256 valLength = getValLength();
        for (uint256 i; i < valLength; i++) {
            string memory validator = valInfo[i].validator;
            uint256 delegationReward = _delegationRewards(validator, address(this));
            totalAmount += delegationReward;
        }
        return totalAmount + pendingFxReward;
    }

    function getVaultConfigs() public view returns (uint256, uint256, uint256, uint256) {
        return (MIN_COMPOUND_AMOUNT, CAP_STAKE_FX_TARGET, UNSTAKE_FX_TARGET, STAKE_FX_TARGET);
    }

    /**************************************** Only Governor Functions ****************************************/

    function addValidator(
        string memory _validator,
        uint256 _allocPoint
    ) external onlyRole(GOVERNOR_ROLE) {
        valInfo[vaultInfo.length].validator = _validator;
        valInfo[vaultInfo.length].allocPoint = _allocPoint;
        vaultInfo.length++;

        vaultInfo.totalAllocPoint += _allocPoint;

        emit ValidatorAdded(_validator, _allocPoint);
    }

    /**
     * @notice remove validators which has 0 allocPoint and 0 delegation in the list 
     */
    function removeValidator() external onlyRole(GOVERNOR_ROLE) {
        VaultInfo memory vault = vaultInfo;
        uint256 vaultLength = vault.length;

        for (uint256 i = 0; i < vaultLength; i++) {
            if (valInfo[i].allocPoint == 0) {
                (uint256 sharesAmount, ) = _delegation(valInfo[i].validator, address(this));
                if (sharesAmount == 0) {
                    uint256 lastIndex = vaultLength - 1;
                    valInfo[i] = valInfo[lastIndex];
                    delete valInfo[lastIndex];
                    vaultLength--;
                    i--;
                }
            }
        }
        vaultInfo.length = vaultLength;
    }

    function updateValidator(
        uint256 id,
        uint256 newAllocPoint
    ) external onlyRole(GOVERNOR_ROLE) {
        require(id < vaultInfo.length, "Invalid ID");
        uint256 oldAllocPoint = valInfo[id].allocPoint;

        vaultInfo.totalAllocPoint = vaultInfo.totalAllocPoint + newAllocPoint - oldAllocPoint;
        valInfo[id].allocPoint = newAllocPoint;

        emit ValidatorUpdated(valInfo[id].validator, newAllocPoint);
    }

    function updateConfigs(uint256 newMinCompound, uint256 newCapStakeFxTarget, uint256 newUnstakeFxTarget, uint256 newStakeFxTarget) external onlyRole(GOVERNOR_ROLE) {
        MIN_COMPOUND_AMOUNT = newMinCompound;
        CAP_STAKE_FX_TARGET = newCapStakeFxTarget;
        UNSTAKE_FX_TARGET = newUnstakeFxTarget;
        STAKE_FX_TARGET = newStakeFxTarget;
    }

    function updateFees(uint256 newFeeOnReward, uint256 newFeeOnWithdrawal) external onlyRole(GOVERNOR_ROLE) {
        feeOnReward = newFeeOnReward;
        feeOnWithdrawal = newFeeOnWithdrawal;
    }

    function sendVestedFX(
        uint256 safeAmount
    ) external onlyVestedFX {
        address recipient = payable(msg.sender);
        (bool success, ) = recipient.call{value: safeAmount}("");
        require(success, "Failed to send FX");
    }

    /**************************************** Only Owner Functions ****************************************/
    function updateVestedFX(address newAddress) external onlyRole(OWNER_ROLE) {
        vestedFX = newAddress;
        emit VestedFXChanged(newAddress);
    }

    function updateFeeTreasury(address newAddress) external onlyRole(OWNER_ROLE) {
        feeTreasury = newAddress;
        emit FeeTreasuryChanged(newAddress);
    }

    function recoverToken(
        address token,
        uint256 amount,
        address _recipient
    ) external onlyRole(OWNER_ROLE) {
        require(_recipient != address(0), "Send to zero address");
        IERC20Upgradeable(token).safeTransfer(_recipient, amount);
    }

    function _authorizeUpgrade(
        address
    ) internal override onlyRole(OWNER_ROLE) {} 

    /**************************************************************
     * @dev Initialize the states
     *************************************************************/

    function initialize(
        address _asset,
        address _owner,
        address _governor
    ) public initializer {
        __BaseVaultInit(
            _asset,
            "Staked FX Token",
            "StFX",
            _owner,
            _governor
        );
        __Governable_init(_owner, _governor);
        __UUPSUpgradeable_init();
    }
}