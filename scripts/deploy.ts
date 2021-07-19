// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
import { Contract, ContractFactory } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Signer } from "crypto";

async function main(): Promise<void> {
  // Hardhat always runs the compile task when running scripts through it.
  // If this runs in a standalone fashion you may want to call compile manually
  // to make sure everything is compiled
  // await run("compile");
  // We get the contract to deploy
  let forge: SignerWithAddress;

  [forge] = await ethers.getSigners();

  const WBTC_ADDRESS = "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599";
  const UNISWAPV2_ADDRESS = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
  const CRV_BTC_ADDRESS = "0x49849C98ae39Fff122806C06791Fa73784FB3675";
  const CRV_ADDRESS = "0xD533a949740bb3306d119CC777fa900bA034cd52";
  const CRV_POOL_ADDRESS = "0x93054188d876f558f4a66B2EF1d97d16eDf0895B";
  const CRV_REWARD_POOL_ADDRESS = "0xB1F2cdeC61db658F091671F5f199635aEF202CAC";

  const CrbWbtcModel: ContractFactory = await ethers.getContractFactory("CrvWbtcModel");
  const wbtcModel: Contract = await CrbWbtcModel.deploy();
  await wbtcModel.deployed();
  console.log("Model deployed to: ", wbtcModel.address);

  await wbtcModel.initialize(
    forge.address,
    WBTC_ADDRESS,
    CRV_BTC_ADDRESS,
    CRV_ADDRESS,
    CRV_POOL_ADDRESS,
    CRV_REWARD_POOL_ADDRESS,
    UNISWAPV2_ADDRESS,
  );

  // console.log(await wbtcModel.invest());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });
