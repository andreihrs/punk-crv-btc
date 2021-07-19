// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../interfaces/ModelInterface.sol";
import "../ModelStorage.sol";
import "../3rdDeFiInterfaces/ICurvePool.sol";
import "../3rdDeFiInterfaces/IUniswapV2Router.sol";
import "../3rdDeFiInterfaces/IRewardsGauge.sol";

import "hardhat/console.sol";

contract CrvWbtcModel is ModelInterface, ModelStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event Swap(uint256 compAmount, uint256 underlying);

    address _btcCrv;
    address _crv;
    address _curvePool;
    address _rewardsGauge;
    address _uRouterV2;
    uint256 public precisionDiv;

    // Slippage tolerances (in basis points)
    uint256 public constant CURVE_SLIPPAGE_TOLERANCE = 2; // 2% CURVE SLIPPAGE WHEN EXCHANGING

    function initialize(
        address forge_,
        address token_,
        address btcCrv_,
        address crv_,
        address curvePool_,
        address rewardsGauge_,
        address uRouterV2_
    ) public {
        addToken(token_);
        setForge(forge_);
        _btcCrv = btcCrv_;
        _crv = crv_;
        _curvePool = curvePool_;
        _rewardsGauge = rewardsGauge_;
        _uRouterV2 = uRouterV2_;
    }

    function underlyingBalanceInModel() public view override returns (uint256) {
        return IERC20(token(0)).balanceOf(address(this));
    }

    function underlyingBalanceWithInvestment() public view override returns (uint256) {
        // Hard Work Now! For Punkers by 0xViktor
        return underlyingBalanceInModel().add(underlyingBalanceInInvestmentPool());
    }

    function underlyingBalanceInInvestmentPool() public view returns (uint256) {
        // Hard Work Now! For Punkers by 0xViktor
        if (balanceOfPool() > 0) {
            return ICurvePool(_curvePool).calc_withdraw_one_coin(balanceOfPool(), 0);
        } else {
            return 0;
        }
    }

    function invest() public override {
        // Hard Work Now! For Punkers by 0xViktor
        uint256 amountToInvest = underlyingBalanceInModel();
        if (amountToInvest > 0) {
            uint256[2] memory amounts = [amountToInvest, 0];

            // IERC20(token(0)).safeApprove(_curvePool, 0);
            // IERC20(token(0)).safeApprove(_curvePool, amountToInvest);

            ICurvePool(_curvePool).add_liquidity(amounts, 0, true);
        }
        uint256 btcCrvBalance = _btcCrvBalance();

        // IERC20(_btcCrv).safeApprove(_rewardsGauge, 0);
        // IERC20(_btcCrv).safeApprove(_rewardsGauge, btcCrvBalance);

        IRewardsGauge(_rewardsGauge).deposit(btcCrvBalance);
        emit Invest(underlyingBalanceInModel(), block.timestamp);
    }

    function reInvest() public {
        // Hard Work Now! For Punkers by 0xViktor
        _claimCrv();
        _swapCrvToUnderlying();
        invest();
    }

    function withdrawAllToForge() public override OnlyForge {
        // Hard Work Now! For Punkers by 0xViktor
        _claimCrv();
        _swapCrvToUnderlying();
        IRewardsGauge(_rewardsGauge).withdraw(balanceOfPool());

        uint256 btcCrvBalance = _btcCrvBalance();

        uint256 minAmount = (ICurvePool(_curvePool).calc_withdraw_one_coin(btcCrvBalance, 0) *
            (100 - CURVE_SLIPPAGE_TOLERANCE)) / 100;

        ICurvePool(_curvePool).remove_liquidity_one_coin(btcCrvBalance, 0, minAmount, true);

        emit Withdraw(underlyingBalanceWithInvestment(), forge(), block.timestamp);

        IERC20(token(0)).safeTransfer(forge(), underlyingBalanceInModel());
    }

    function withdrawToForge(uint256 amount) public override OnlyForge {
        withdrawTo(amount, forge());
    }

    function withdrawTo(uint256 amount, address to) public override OnlyForge {
        // Hard Work Now! For Punkers by 0xViktor
        uint256 oldBalance = IERC20(token(0)).balanceOf(address(this));

        if (underlyingBalanceInModel() < amount) {
            uint256[2] memory amounts = [amount, 0];
            uint256 crvAmount = ICurvePool(_curvePool).calc_token_amount(amounts, false);

            IRewardsGauge(_rewardsGauge).withdraw(crvAmount);

            uint256 btcCrvBalance = _btcCrvBalance();

            uint256 minAmount = (ICurvePool(_curvePool).calc_withdraw_one_coin(btcCrvBalance, 0) *
                (100 - CURVE_SLIPPAGE_TOLERANCE)) / 100;

            ICurvePool(_curvePool).remove_liquidity_one_coin(btcCrvBalance, 0, minAmount, true);
        }

        uint256 newBalance = IERC20(token(0)).balanceOf(address(this));
        require(newBalance.sub(oldBalance) > 0, "MODEL : REDEEM BALANCE IS ZERO");
        IERC20(token(0)).safeTransfer(to, newBalance.sub(oldBalance));

        emit Withdraw(amount, forge(), block.timestamp);
    }

    function balanceOfPool() public view returns (uint256) {
        IRewardsGauge(_rewardsGauge).balanceOf(address(this));
    }

    function _btcCrvBalance() internal view returns (uint256) {
        return IERC20(_btcCrv).balanceOf(address(this));
    }

    function _crvBalance() internal view returns (uint256) {
        return IERC20(_crv).balanceOf(address(this));
    }

    function _claimCrv() internal {
        // Hard Work Now! For Punkers by 0xViktor
        IRewardsGauge(_rewardsGauge).claim_rewards(address(this));
    }

    function _swapCrvToUnderlying() internal {
        // Hard Work Now! For Punkers by 0xViktor
        uint256 balance = IERC20(_crv).balanceOf(address(this));
        if (balance > 0) {
            IERC20(_crv).safeApprove(_uRouterV2, 0);
            IERC20(_crv).safeApprove(_uRouterV2, balance);

            address[] memory path = new address[](3);
            path[0] = address(_crv);
            path[1] = IUniswapV2Router02(_uRouterV2).WETH();
            path[2] = address(token(0));

            IUniswapV2Router02(_uRouterV2).swapExactTokensForTokens(
                balance,
                1,
                path,
                address(this),
                block.timestamp + (15 * 60)
            );

            emit Swap(balance, underlyingBalanceInModel());
        }
    }
}
