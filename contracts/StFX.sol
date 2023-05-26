// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface IStaking {

    function delegation(string memory _val, address _del) external view returns (uint256, uint256);

}

interface IAutoCompound {

    function getValLength() external view returns (uint256);

    function getDelegationInfo(uint256 index) external view returns (string memory, uint256);

}

contract StFX is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    IAutoCompound autoCompound;
    IStaking stakingContract;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _stakingContract) initializer public {
        stakingContract = IStaking(_stakingContract);
        __ERC20_init("StFX", "STFX");
        __ERC20Burnable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    event AutoCompoundChanged(address newAddress);

    function mint(address to, uint256 amount) public onlyAutoCompound {
        _mint(to, amount);
    }

    function burn(uint256 amount) public override onlyAutoCompound {
        _burn(msg.sender, amount);
    }

    function totalDelegatedFX() public view returns (uint256) {
        uint256 totalAmount;
        uint256 valLength = autoCompound.getValLength();
        for (uint256 i; i < valLength; ++i) {
            (string memory validator, ) = autoCompound.getDelegationInfo(i);
            (, uint256 delegationAmount) = stakingContract.delegation(validator, address(autoCompound));
            totalAmount += delegationAmount;
        }
        return totalAmount;
    }

    function getPooledFXByShares(uint256 sharesAmount) external view returns (uint256) {
        uint256 totalShares = totalSupply();
        if (totalShares == 0) {
            return 0;
        } else {
            return sharesAmount * totalDelegatedFX() / totalShares;
        }
    }

    function getSharesByPooledFX(uint256 fxAmount, uint256 delegateReward) external view returns (uint256) {
        uint256 totalPooledFX = totalDelegatedFX() + delegateReward;
        if (totalPooledFX == 0) {
            return 0;
        } else {
            return fxAmount * totalSupply() / totalPooledFX;
        }
    }

    function updateAutoCompound(address newAddress) external onlyOwner {
        autoCompound = IAutoCompound(newAddress);
        emit AutoCompoundChanged(newAddress);
    }

    modifier onlyAutoCompound() {
        require(msg.sender == address(autoCompound), "Only AutoCompound can call");
        _;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}