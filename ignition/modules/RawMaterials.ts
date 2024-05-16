import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const RawMaterialsModule = buildModule("RawMaterialsModule", (m) => {
  const rawMaterials = m.contract("RawMaterials");

  return { rawMaterials };
});

export default RawMaterialsModule;
