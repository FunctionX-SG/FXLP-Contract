pragma solidity ^0.8.18;

library Encode {
    function delegate(
        string memory _validator
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSignature("delegate(string)", _validator);
    }

    function undelegate(
        string memory _validator,
        uint256 _shares
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSignature("undelegate(string,uint256)", _validator, _shares);
    }

    function withdraw(
        string memory _validator
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSignature("withdraw(string)", _validator);
    }

    function transferFromShares(
        string memory _validator,
        address _from,
        address _to,
        uint256 _shares
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSignature("transferFromShares(string,address,address,uint256)", _validator, _from, _to, _shares);
    }

    function delegation(
        string memory _validator,
        address _delegate
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSignature("delegation(string,address)", _validator, _delegate);
    }

    function delegationRewards(
        string memory _validator, 
        address _delegate) internal pure returns (bytes memory) {
        return abi.encodeWithSignature("delegationRewards(string,address)", _validator, _delegate);
    }
}

pragma solidity ^0.8.18;

library Decode {
    function delegate(
        bytes memory data
    ) internal pure returns (uint256, uint256) {
        (uint256 shares, uint256 reward) = abi.decode(data, (uint256, uint256));
        return (shares, reward);
    }

    function undelegate(
        bytes memory data
    ) internal pure returns (uint256, uint256, uint256) {
        (uint256 amount, uint256 reward, uint256 endTime) = abi.decode(
            data,
            (uint256, uint256, uint256)
        );
        return (amount, reward, endTime);
    }

    function withdraw(bytes memory data) internal pure returns (uint256) {
        uint256 reward = abi.decode(data, (uint256));
        return reward;
    }

    function transferFromShares(bytes memory data) internal pure returns (uint256, uint256) {
        (uint256 token, uint256 reward) = abi.decode(data, (uint256, uint256));
        return (token, reward);
    }

    function delegation(bytes memory data) internal pure returns (uint256, uint256) {
        (uint256 delegateShare, uint256 delegateAmount) = abi.decode(data, (uint256, uint256));
        return (delegateShare, delegateAmount);
    }

    function delegationRewards(bytes memory data) internal pure returns (uint256) {
        uint256 rewardAmount= abi.decode(data, (uint256));
        return rewardAmount;
    }

    function ok(
        bool _result,
        bytes memory _data,
        string memory _msg
    ) internal pure {
        if (!_result) {
            string memory errMsg = abi.decode(_data, (string));
            if (bytes(_msg).length < 1) {
                revert(errMsg);
            }
            revert(string(abi.encodePacked(_msg, ": ", errMsg)));
        }
    }
}

abstract contract PrecompileStaking {

    address private constant _stakingAddress = address(0x0000000000000000000000000000000000001003);

    /**************************************** Precompile Staking Internal Functions ****************************************/

    function _delegate(string memory _val, uint256 _amount) internal returns (uint256, uint256) {
        (bool result, bytes memory data) = _stakingAddress.call{value: _amount}(Encode.delegate(_val));
        Decode.ok(result, data, "delegate failed");

        return Decode.delegate(data);
    }

    function _undelegate(string memory _val, uint256 _shares) internal returns (uint256, uint256, uint256) {
        (bool result, bytes memory data) = _stakingAddress.call(Encode.undelegate(_val, _shares));
        Decode.ok(result, data, "undelegate failed");

        return Decode.undelegate(data);
    }

    function _withdraw(string memory _val) internal returns (uint256) {
        (bool result, bytes memory data) = _stakingAddress.call(Encode.withdraw(_val));
        Decode.ok(result, data, "withdraw failed");

        return Decode.withdraw(data);
    }

    function _transferFromShares(string memory _val, address _from, address _to, uint256 _shares) internal returns (uint256, uint256) {
        (bool result, bytes memory data) = _stakingAddress.call(Encode.transferFromShares(_val, _from, _to, _shares));
        Decode.ok(result, data, "transferFromShares failed");

        return Decode.transferFromShares(data);
    }

    function _delegation(string memory _val, address _del) internal view returns (uint256, uint256) {
        (bool result, bytes memory data) = _stakingAddress.staticcall(Encode.delegation(_val, _del));
        Decode.ok(result, data, "delegation failed");

        return Decode.delegation(data);
    }

    function _delegationRewards(string memory _val, address _del) internal view returns (uint256) {
        (bool result, bytes memory data) = _stakingAddress.staticcall(Encode.delegationRewards(_val, _del));
        Decode.ok(result, data, "delegationRewards failed");

        return Decode.delegationRewards(data);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract test is PrecompileStaking{

    string private val = "fxvaloper1t67ryvnqmnud5g3vpmck00l3umelwkz7huh0s3";
    string private val1 = "fxvaloper1etzrlsszsm0jaj4dp5l25vk3p4w0x4ntl64hlw";

    function stake(uint256 index) external payable {
        _stake(index);
    }

    function _stake(uint256 index) internal {
        uint256 amount = 100000000000000000000;
        for (uint256 i =0; i< index; i++) {
            _delegate(val, amount);
        }        
    }  

    function stake1(uint256 index) external payable {
        _stake1(index);
    }

    function _stake1(uint256 index) internal {
        uint256 amount = 100000000000000000000;
        for (uint256 i =0; i< index; i++) {
            _delegate(val, amount);
            _delegate(val1, amount);
        }        
    }  

    function getDelegationInfo() external view returns (uint256, uint256) {
        (uint256 sharesAmount, uint256 delegationAmount) = _delegation(val, address(this));
        return (sharesAmount, delegationAmount);
    }

    function getDelegationInfo1() external view returns (uint256, uint256) {
        (uint256 sharesAmount, uint256 delegationAmount) = _delegation(val1, address(this));
        return (sharesAmount, delegationAmount);
    }
}

interface test2 {
    function stake() external payable;

    function totalAssets() external view returns(uint256);
    
}