import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const SupplyChainModule = buildModule("SupplyChainModule", (m) => {
  const supplyChain = m.contract("SupplyChain", [
    "0x9beeD5049070C852b43d82C57FA71062a8531872",
    "0x6f757F3ab0765ffbCc0EAf9220241815135B5c86",
    "0xd501F292b7A8f77329B50f02565a178ADa4C86B9",
  ]);

  return { supplyChain };
});

export default SupplyChainModule;
