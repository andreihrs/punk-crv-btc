// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IComptroller {
    function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);

    function exitMarket(address cToken) external returns (uint256);

    function claimComp(address holder) external;
}
