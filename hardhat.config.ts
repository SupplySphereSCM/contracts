import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox-viem";
import "@nomicfoundation/hardhat-chai-matchers";
import "@nomicfoundation/hardhat-viem";
import * as dotenv from "dotenv";

dotenv.config({
  path: ".env",
});

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  networks: {
    hardhat: {
      accounts: {
        mnemonic: process.env.MNEMONICS,
      },
    },
    ganache: {
      chainId: 1337,
      url: "http://127.0.0.1:7545",
      accounts: {
        mnemonic: process.env.MNEMONICS,
      },
    },
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
