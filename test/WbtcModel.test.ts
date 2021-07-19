import hre, { ethers, artifacts } from "hardhat";
import chai, { use } from "chai";
import { solidity } from "ethereum-waffle";
import { IUniswapV2Router02, IERC20, CrvWbtcModel } from "../typechain";
import { Contract, BigNumber, BigNumberish } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

chai.use(solidity);
const { expect } = chai;

const toWei = ethers.utils.parseEther;
// use(require("chai-bignumber"));

describe("Wbtc Model", () => {
  let underlying: Contract;

  let deployer: SignerWithAddress;
  let forge: SignerWithAddress;
  let farmer: SignerWithAddress;

  let wbtcModel: Contract;

  const WBTC_ADDRESS = "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599";
  const UNISWAPV2_ADDRESS = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
  const CRV_BTC_ADDRESS = "0x49849C98ae39Fff122806C06791Fa73784FB3675";
  const CRV_ADDRESS = "0xD533a949740bb3306d119CC777fa900bA034cd52";
  const CRV_POOL_ADDRESS = "0x93054188d876f558f4a66B2EF1d97d16eDf0895B";
  const CRV_REWARD_POOL_ADDRESS = "0xB1F2cdeC61db658F091671F5f199635aEF202CAC";

  const WBTC_DECIMALS = 8;
  const WBTC_EXP_SCALE = BigNumber.from(10).pow(WBTC_DECIMALS);
  const amount = BigNumber.from(10).mul(WBTC_EXP_SCALE); // wBTC amount

  const formatValue = async (token: Contract, value: BigNumberish): Promise<string> =>
    ethers.utils.formatUnits(value, await token.decimals());

  const formatBalance = async (token: Contract, account: string): Promise<string> =>
    formatValue(token, await token.balanceOf(account));

  before(async () => {
    [deployer, forge, farmer] = await ethers.getSigners();

    // underlying = (await getVerifiedContractAt(WBTC_ADDRESS)) as IERC20;
    underlying = await ethers.getContractAt("ERC20", WBTC_ADDRESS);

    const underlyingWhaleAddress = "0x28C6c06298d514Db089934071355E5743bf21d60"; // Binance Wallet
    await ethers.provider.send("hardhat_impersonateAccount", [underlyingWhaleAddress]);
    const underlyingWhale = await ethers.getSigner(underlyingWhaleAddress);

    await underlying
      .connect(underlyingWhale)
      .transfer(farmer.address, await underlying.balanceOf(underlyingWhaleAddress));

    let WbtcModelFactory = await ethers.getContractFactory("CrvWbtcModel");
    wbtcModel = (await WbtcModelFactory.deploy()) as CrvWbtcModel;

    const IUniswapV2Router = await artifacts.readArtifact("IUniswapV2Router02");
    const uniswapRouter = await ethers.getContractAt(IUniswapV2Router.abi, UNISWAPV2_ADDRESS);

    await wbtcModel.initialize(
      forge.address,
      WBTC_ADDRESS,
      CRV_BTC_ADDRESS,
      CRV_ADDRESS,
      CRV_POOL_ADDRESS,
      CRV_REWARD_POOL_ADDRESS,
      UNISWAPV2_ADDRESS,
    );
  });

  it("initial balance", async () => {
    expect(await wbtcModel.underlyingBalanceInModel()).to.eq(0);
    console.log("BALANCE", await formatBalance(underlying, farmer.address));
    expect(await wbtcModel.underlyingBalanceWithInvestment()).to.eq(0);
  });

  it("invest", async () => {
    expect(await wbtcModel.underlyingBalanceWithInvestment()).to.eq(0);
    await underlying.connect(farmer).transfer(wbtcModel.address, amount);
    await wbtcModel.invest();
    expect(await wbtcModel.underlyingBalanceWithInvestment()).not.to.eq(0);
  });
});
