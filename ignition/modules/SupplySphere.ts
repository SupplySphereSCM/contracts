import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const SupplySphereModule = buildModule("SupplySphereModule", (m) => {
  const supplySphere = m.contract("SupplySphere", [
    "0xa818d81E54b927AE6E5bA510434820cd3e9eB02d",
    "0x9beeD5049070C852b43d82C57FA71062a8531872",
    "0x2e7E82e2B2177DAD4a40c291b1ae05C3291e4001",
    "0x6f757F3ab0765ffbCc0EAf9220241815135B5c86",
    "0xd501F292b7A8f77329B50f02565a178ADa4C86B9",
    "0xa6C898E7FeD4Ee140B1260a87d20dE6058D392e4",
  ]);

  return { supplySphere };
});

export default SupplySphereModule;
