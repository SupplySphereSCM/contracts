import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox-viem";
import "@nomicfoundation/hardhat-chai-matchers";
import "@nomicfoundation/hardhat-viem";
import * as dotenv from "dotenv";

dotenv.config({
  path: "./",
});

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  networks: {
    amoy: {
      chainId: 80002,
      url: "https://rpc-amoy.polygon.technology/",
      accounts: {
        mnemonic: process.env.MNEMONICS,
      },
    },
  },
};

export default config;
