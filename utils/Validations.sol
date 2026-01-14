// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

abstract contract Validations {
    error Validations__MustBeMoreThanZero();

    modifier moreThanZero(uint256 _amount) {
        if (_amount <= 0) revert Validations__MustBeMoreThanZero();
        _;
    }
}
