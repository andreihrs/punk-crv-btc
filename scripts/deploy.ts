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
  const WBTC = "0x3b92f58feD223E2cB1bCe4c286BD97e42f2A12EA";
  const UniswapV2Router = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
  const btcCrv = "0xa1faa15655b0e7b6b6470ed3d096390e6ad93abb";
  const crv = "0x61460874a7196d6a22d1ee4922473664b3e95270";

  const CrbWbtcModel: ContractFactory = await ethers.getContractFactory("CrvWbtcModel");
  const wbtcModel: Contract = await WbtcModel.deploy();
  await wbtcModel.deployed();
  console.log("Model deployed to: ", wbtcModel.address);

  await wbtcModel.initialize(forge.address, WBTC, cWBTC, COMP, comptroller, UniswapV2Router);

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
