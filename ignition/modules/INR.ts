import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const INRModule = buildModule("INRModule", (m) => {
  const inr = m.contract("INR");

  return { inr };
});

export default INRModule;
