import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const LogisticsModule = buildModule("LogisticsModule", (m) => {
  const logistics = m.contract("Logistics");

  return { logistics };
});

export default LogisticsModule;
