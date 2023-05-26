// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IStFX {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function balanceOf(address tokenOwner) external view returns (uint256);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function getPooledFXByShares(uint256 sharesAmount) external view returns (uint256);

    function getSharesByPooledFX(uint256 fxAmount, uint256 delegateReward) external view returns (uint256);
}

interface IStaking {
    function delegate(string memory _val) external payable returns (uint256, uint256);

    function undelegate(string memory _val, uint256 _shares) external returns (uint256, uint256, uint256);

    function withdraw(string memory _val) external returns (uint256);

    function delegation(string memory _val, address _del) external view returns (uint256, uint256);

    function approveShares(string memory _val, address _spender, uint256 _shares) external returns (bool);

    function transferFromShares(string memory _val, address _from, address _to, uint256 _shares) external returns (uint256, uint256);
}

interface IVestedFX {
    function updateEndTimeAndAmount(address user, uint256 endTime, uint256 undelegateAmount) external;
}

contract AutoCompound is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    
    using SafeERC20Upgradeable for IERC20Upgradeable;
    
    string public name;

    mapping(address => bool) public authorized;
    VaultInfo public vaultInfo;
    ValInfo public valInfo;

    IStFX stFX;
    IStaking stakingContract;
    IVestedFX vestedFX;
    
    struct ValInfo {
        uint256 stakeId;
        uint256 unstakeId;
        uint256 length;
        uint256 inUseLength;
        uint256 size;
        uint256 stakeTarget;
        uint256 totalAllocPoint;
        mapping(uint256 => Delegation) data;
    }

    struct Delegation {
        uint256 allocPoint;
        string validator;
    }

    struct VaultInfo {
        uint256 unbufferedFX; // FX rewards in the contract
        uint256 feeOnReward;
        bool stakingEnabled;
    }

    event Stake(address indexed user, uint256 amount, uint256 shares);
    
    event Unstake(address indexed user, uint256 amount, uint256 shares);

    event ValidatorUpdated(string val, uint256 newAllocPoint);

    event ValidatorAdded(string val, uint256 newAllocPoint);

    event ManualCompound(address indexed user, uint256 amount);

    event StakingEnabled(bool newValue);

    event VestedFXChanged(address newAddress);

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner() == msg.sender, "Not authorised");
        _;
    }

    modifier onlyVestedFX() {
        require(msg.sender == address(vestedFX), "Only VestedFX can call");
        _;
    }
    /****************************************** Core Functions ******************************************/

    function stake() external payable {
        require(msg.value !=0, "Stake: 0 amount");
        require(vaultInfo.stakingEnabled == true, "Staking not enabled");
        
        uint256 delegateReward = withdraw() + vaultInfo.unbufferedFX;
        uint256 feeOnReward = delegateReward * vaultInfo.feeOnReward / 1e20;
        delegateReward -= feeOnReward;

        uint256 sharesAmount = stFX.getSharesByPooledFX(msg.value, delegateReward);
        
        // If first deposit or complete slashing, assume shares correspond to FX 1-to-1
        if (sharesAmount == 0) {
            sharesAmount = msg.value;
        }

        stFX.mint(msg.sender, sharesAmount);
        
        uint256 delegateAmount = delegateReward + msg.value;

        toDelegate(delegateAmount);

        emit Stake(msg.sender, msg.value, sharesAmount);
    } 

    function unstake(uint256 amount) external {
        require(amount != 0, "Unstake: 0 amount");

        uint256 sharesBalance = stFX.balanceOf(msg.sender);    
        require(sharesBalance >= amount, "Amount exceeds stake");

        uint256 undelegateAmount = stFX.getPooledFXByShares(amount);

        stFX.transferFrom(msg.sender, address(this), amount);
       
        toUndelegate(undelegateAmount);
       
        stFX.burn(amount); 

        emit Unstake(msg.sender, undelegateAmount, amount);
    }

    function redelegate(string memory _val, uint256 _amount) external {
        require(_amount > 0, "Redelegate: 0 amount");
        
        (uint256 shares, uint256 amount) = stakingContract.delegation(_val, msg.sender);
        require (amount > 0, "0 delegation amount");

        uint256 sharesForRedelegate = _amount * shares / amount;
        sharesForRedelegate < shares ? sharesForRedelegate : shares;

        (uint256 delegatedFX, uint256 rewardFX) = stakingContract.transferFromShares(_val, msg.sender, address(this), sharesForRedelegate);
        uint256 totalFX = delegatedFX + rewardFX;
        
        uint256 delegateReward = withdraw() + vaultInfo.unbufferedFX;
        uint256 feeOnReward = delegateReward * vaultInfo.feeOnReward / 1e20;
        delegateReward -= feeOnReward;

        uint256 sharesAmount = stFX.getSharesByPooledFX(totalFX, delegateReward);
        if (sharesAmount == 0) {
            sharesAmount = totalFX;
        }

        stFX.mint(msg.sender, sharesAmount);
        uint256 delegateAmount = delegateReward + rewardFX;

        toDelegate(delegateAmount);
    }

    /**************************************** Internal and View Functions ****************************************/
 
    function withdraw() internal returns (uint256) {
        uint256 claimedReward;
        for (uint256 i; i < valInfo.length; ++i) {
            claimedReward += stakingContract.withdraw(valInfo.data[i].validator);
        }
        return claimedReward;
    }

    function toUndelegate(uint256 undelegateAmount) internal {
        uint256 numValidators = calculateNumberofValidators(undelegateAmount);
        uint256 totalDelegatedAmount;
        uint256 numValidatorsToUse;
        uint256 totalReward;
        uint256 delegationAmountMoreThanSize = undelegateAmount;

        for (uint256 i = valInfo.unstakeId; i < valInfo.unstakeId + valInfo.length; i = (i + 1) % valInfo.length) {
            (, uint256 delegationAmount) = stakingContract.delegation(valInfo.data[i].validator, address(this));
            if (delegationAmount == 0) {
                continue;
            } 
            
            if (delegationAmount <= valInfo.size) {
                delegationAmountMoreThanSize -= delegationAmount;
            } else {
                totalDelegatedAmount += delegationAmount;
            }

            numValidatorsToUse++;

            if (totalDelegatedAmount >= delegationAmountMoreThanSize && numValidatorsToUse >= numValidators) {
                break;
            }
        }

        uint256 index = valInfo.unstakeId;
        uint256 counter;
        uint256 totalUndelegated;

        while (counter < numValidatorsToUse) {
            (uint256 share, uint256 amount) = stakingContract.delegation(valInfo.data[index].validator, address(this));

            if (amount == 0 || share == 0) {
                index = (index + 1) % valInfo.length;
                continue;
            }

            uint256 amountToUndelegate;
            if (amount <= valInfo.size) {
                amountToUndelegate = amount;
                if (counter + 1 == numValidatorsToUse) {
                    amountToUndelegate = undelegateAmount - totalUndelegated;
                }
            } else {
                amountToUndelegate = delegationAmountMoreThanSize * amount / totalDelegatedAmount;
            }

            uint256 shareToWithdraw = share * amountToUndelegate / amount;
                
            ( , uint256 reward, uint256 endTime) = stakingContract.undelegate(valInfo.data[index].validator, shareToWithdraw);
            vestedFX.updateEndTimeAndAmount(msg.sender, endTime, amountToUndelegate);

            totalUndelegated += amountToUndelegate;
            totalReward += reward;
            counter++;
            index = (index + 1) % valInfo.length;
        }

        valInfo.unstakeId = index;
        vaultInfo.unbufferedFX += totalReward;
    }

    function toDelegate(uint256 delegateAmount) internal {
        uint256 totalDelegatedAmount;

        if (delegateAmount <= valInfo.stakeTarget) {
            uint256 numValidators = calculateNumberofValidators(delegateAmount);

            numValidators = numValidators > valInfo.inUseLength ? valInfo.inUseLength : numValidators;

            uint256 amountPerValidator = delegateAmount / numValidators;
            uint256 index;

            for (uint256 i = valInfo.stakeId; i < valInfo.stakeId + valInfo.length; ++i) {
                index = i % valInfo.length;
                
                if (valInfo.data[index].allocPoint == 0) {
                    continue;
                }
                if (numValidators == 1) {
                    stakingContract.delegate{value: delegateAmount}(valInfo.data[index].validator);
                    break;
                }
                if (totalDelegatedAmount + amountPerValidator >= delegateAmount) {
                    uint256 remainingAmount = delegateAmount - totalDelegatedAmount;
                    stakingContract.delegate{value: remainingAmount}(valInfo.data[index].validator);
                    break;
                }
                stakingContract.delegate{value: amountPerValidator}(valInfo.data[index].validator);
                totalDelegatedAmount += amountPerValidator;
            }

            valInfo.stakeId = (index + 1) % valInfo.length;
        } else {
            uint256 newTotalAllocPoint = valInfo.totalAllocPoint;

            for (uint256 i; i < valInfo.length; ++i) {                
                uint256 allocPoint = valInfo.data[i].allocPoint;
                uint256 newDelegateAmount = 0;

                if (allocPoint == 0) {
                    continue;
                }
                newDelegateAmount = allocPoint * (delegateAmount - totalDelegatedAmount) / newTotalAllocPoint;
                newTotalAllocPoint -= allocPoint;

                if (newDelegateAmount == 0) {
                    continue;
                }
                stakingContract.delegate{value: newDelegateAmount}(valInfo.data[i].validator);
                totalDelegatedAmount += newDelegateAmount;

                if (totalDelegatedAmount == delegateAmount) {
                    break;
                }
            }
        }
    } 

    function calculateNumberofValidators(uint256 delegateAmount) internal view returns (uint256) {
        uint256 numValidators = delegateAmount / valInfo.size;
        return (numValidators == 0) ? 1 : numValidators;
    }

    function getValLength() external view returns (uint256) {
        return valInfo.length;
    }

    function getDelegationInfo(uint256 index) external view returns (string memory, uint256) {
        return (valInfo.data[index].validator, valInfo.data[index].allocPoint);
    }

    /**************************************** Only Authorised Functions ****************************************/

    function sendVestedFX(uint256 safeAmount, address _recipient) external onlyVestedFX {
        address recipient = payable(_recipient);
        (bool success, ) = recipient.call{value: safeAmount}("");
        require(success, "Failed to send FX");
    }

    function addValidator(string memory val, uint256 newAllocPoint) external onlyAuthorized {
        valInfo.data[valInfo.length].validator = val;
        valInfo.data[valInfo.length].allocPoint = newAllocPoint;
        valInfo.length++;
        if (newAllocPoint != 0){
            valInfo.inUseLength++;
        }
        valInfo.totalAllocPoint += newAllocPoint;

        emit ValidatorAdded(val, newAllocPoint);
    }

    function removeValidator() external onlyAuthorized {
        uint256 numRemovedValidators;
        for (uint256 i = 0; i < valInfo.length - numRemovedValidators; i++) {
            if (valInfo.data[i].allocPoint == 0) {
                (, uint256 delegationAmount) = stakingContract.delegation(valInfo.data[i].validator, address(this));
                if (delegationAmount == 0) {
                    uint256 lastIndex = valInfo.length - numRemovedValidators - 1;
                    valInfo.data[i] = valInfo.data[lastIndex];
                    delete valInfo.data[lastIndex];
                    valInfo.length--;
                    numRemovedValidators++;
                    i--;
                }
            }
        }
    }

    function updateValidator(uint256 id, uint256 newAllocPoint) external onlyAuthorized {
        require(id < valInfo.length, "Invalid ID");
        uint256 oldAllocPoint = valInfo.data[id].allocPoint;
        valInfo.totalAllocPoint = valInfo.totalAllocPoint - oldAllocPoint + newAllocPoint;
        valInfo.data[id].allocPoint = newAllocPoint;

        if (oldAllocPoint == 0 && newAllocPoint != 0) {
            valInfo.inUseLength++;
        } else if (oldAllocPoint != 0 && newAllocPoint == 0) {
            valInfo.inUseLength--;
        }
        
        emit ValidatorUpdated(valInfo.data[id].validator, newAllocPoint);
    }

    function manualCompound() external onlyAuthorized {
        uint256 delegateAmount = withdraw() + vaultInfo.unbufferedFX;
        uint256 amountToDelegate = delegateAmount * (1e20 - vaultInfo.feeOnReward) / 1e20;
        toDelegate(amountToDelegate);
        
        emit ManualCompound(msg.sender, amountToDelegate);
    }

    function updateTarget(uint256 newTarget) external onlyAuthorized {
        valInfo.stakeTarget = newTarget;
    }

    function updateFeeOnReward(uint256 _feeOnReward) external onlyAuthorized {
        vaultInfo.feeOnReward = _feeOnReward;
    }

    function updateSize(uint256 _size) external onlyAuthorized {
        valInfo.size = _size;
    }
   
    function updateStakingEnabled(bool newValue) external onlyOwner {
        vaultInfo.stakingEnabled = newValue;
        emit StakingEnabled(newValue);
    }

    function updateVestedFX(address newAddress) external onlyOwner {
        vestedFX = IVestedFX(newAddress);
        emit VestedFXChanged(newAddress);
    }

    function recoverToken(address token, uint256 amount, address recipient) external onlyOwner {
        require(recipient != address(0), "Send to zero address");
        IERC20Upgradeable(token).safeTransfer(recipient, amount);
    }

    function addAuthorised(address user) external onlyOwner {
        authorized[user] = true;
    }

    function removeAuthorised(address user) external onlyOwner {
        authorized[user] = false;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /********** Only For Testing - To Be Removed **********/

    function depositFX() payable external {
        require(msg.value > 0, "Zero value");
    }

    function updateInUseLength(uint256 newLength) external {
        valInfo.inUseLength = newLength;
    }
    /**************************************************************
     * @dev Initialize the states
     * @param name: AutoCompound
     *************************************************************/

    function initialize(address _stFX, address _stakingContract, uint256 _target, uint256 _size) public initializer {
        name = "AutoCompound";
        stFX = IStFX(_stFX);
        vaultInfo.stakingEnabled = true;
        stakingContract = IStaking(_stakingContract);
        valInfo.stakeTarget = _target;
        valInfo.size = _size;

        __Ownable_init();
        __UUPSUpgradeable_init();
    }

}