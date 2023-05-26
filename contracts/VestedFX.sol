// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IAutoCompound {

    function sendVestedFX(uint256 safeAmount, address recipient) external;

}

contract VestedFX is Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    
    using SafeERC20Upgradeable for IERC20Upgradeable;
    
    string public name;

    IAutoCompound private autoCompound;

    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 length;
        uint256 startId;
        mapping(uint256 => Undelegation) data;
    }

    struct Undelegation {
        uint256 endTime;
        uint256 undelegateAmount;
    }

    event ClaimVestedFX(address indexed user, uint256 amount);

    modifier onlyAutoCompound() {
        require(msg.sender == address(autoCompound), "Only AutoCompound can call");
        _;
    }

    /****************************************** Core Functions ******************************************/

    function claimVestedFX() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.length > 0, "No vesting data");

        uint256 amount = 0;
        uint256 dataLength = user.length;
        uint256 i = user.startId;

        for (i; i < dataLength; ++i) {
            if (block.timestamp >= user.data[i].endTime) {
                amount += user.data[i].undelegateAmount;
                user.data[i].undelegateAmount = 0;
                user.startId = i + 1;
            } else {
                break; // The rest of the vesting data is not ready for claim yet
            }
        }
        require(amount > 0, "Nothing to claim");

        uint256 safeAmount = amount;
        if (address(autoCompound).balance < amount) {
            safeAmount = address(autoCompound).balance;
        }
        require(safeAmount > 0, "Insufficient FX");

        autoCompound.sendVestedFX(safeAmount, msg.sender);

        emit ClaimVestedFX(msg.sender, safeAmount);
    }

    /**************************************** Internal and View Functions ****************************************/

    function getUndelegationInfo(address user, uint256 id) external view returns (uint256, uint256) {
        return (userInfo[user].data[id].undelegateAmount, userInfo[user].data[id].endTime);
    }

    function getUserInfo(address user) external view returns (uint256, uint256) {
        return (userInfo[user].length, userInfo[user].startId);
    }

    /**************************************** Only Authorised Functions ****************************************/
    
    function updateEndTimeAndAmount(address _user, uint256 endTime, uint256 undelegateAmount) external onlyAutoCompound {
        UserInfo storage user = userInfo[_user];
        uint256 getId = user.length;
        user.length = getId + 1;
        user.data[getId].endTime = endTime;
        user.data[getId].undelegateAmount = undelegateAmount;
        userInfo[_user].length;
    }

    function recoverToken(address token, uint256 amount, address recipient) external onlyOwner nonReentrant{
        require(recipient != address(0), "Send to zero address");
        IERC20Upgradeable(token).safeTransfer(recipient, amount);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**************************************************************
     * @dev Initialize the states
     * @param name: VestedFX
     *************************************************************/

    function initialize(address _autoCompound) public initializer {
        name = "VestedFX";
        autoCompound = IAutoCompound(_autoCompound);

        __Ownable_init();
        __UUPSUpgradeable_init();
    }

}