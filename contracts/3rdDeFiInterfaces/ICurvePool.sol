// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ICurvePool {
    function get_virtual_price() external view returns (uint256);

    // _use_underlying If True, withdraw underlying assets instead of aTokens
    function add_liquidity(
        uint256[2] calldata amounts,
        uint256 min_mint_amount,
        bool _use_underlying
    ) external;

    function remove_liquidity(
        uint256 _amount,
        uint256[2] calldata _min_amounts,
        bool _use_underlying
    ) external returns (uint256[2] memory amounts);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount,
        bool _use_underlying
    ) external returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function calc_token_amount(uint256[2] calldata _amounts, bool is_deposit) external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);
}
