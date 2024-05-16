import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const ServicesModule = buildModule("ServicesModule", (m) => {
  const services = m.contract("Services");

  return { services };
});

export default ServicesModule;
