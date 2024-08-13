// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import {Encode} from "../libraries/Encode.sol";
import {Decode} from "../libraries/Decode.sol";
import {IPrecompileStaking} from "../interfaces/IPrecompileStaking.sol";

/**
 * @title PrecompileStaking
 *
 * @dev Interface to interact to network precompile staking contract functions.
 */
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

    function _redelegate(string memory _valSrc, string memory _valDst, uint256 _shares) internal returns (uint256, uint256, uint256) {
        (bool result, bytes memory data) = _stakingAddress.call(Encode.redelegate(_valSrc, _valDst, _shares));
        Decode.ok(result, data, "redelegate failed");

        return Decode.redelegate(data);
    }

    function _delegateV2(string memory _val, uint256 _amount) internal returns (bool _result) {
        require(address(this).balance >= _amount, "insufficient balance");
        return IPrecompileStaking(_stakingAddress).delegateV2(_val, _amount);
    }

    function _undelegateV2(string memory _val, uint256 _amount) internal returns (bool _result) {
        return IPrecompileStaking(_stakingAddress).undelegateV2(_val,_amount);
    }

    function _redelegateV2(string memory _valSrc, string memory _valDst, uint256 _amount) internal returns (bool _result) {
        return IPrecompileStaking(_stakingAddress).redelegateV2(_valSrc, _valDst, _amount);
    }

    function _withdraw(string memory _val) internal returns (uint256) {
        (bool result, bytes memory data) = _stakingAddress.call(Encode.withdraw(_val));
        Decode.ok(result, data, "withdraw failed");

        return Decode.withdraw(data);
    }

    function _transferShares(string memory _val, address _to, uint256 _shares) internal returns (uint256, uint256) {
        (bool result, bytes memory data) = _stakingAddress.call(Encode.transferShares(_val, _to, _shares));
        Decode.ok(result, data, "transferShares failed");

        return Decode.transferShares(data);
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

    function _allowanceShares(string memory _val, address _owner, address _spender) internal view returns (uint256) {
        (bool result, bytes memory data) = _stakingAddress.staticcall(Encode.allowanceShares(_val, _owner, _spender));
        Decode.ok(result, data, "allowanceShares failed");

        return Decode.allowanceShares(data);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}