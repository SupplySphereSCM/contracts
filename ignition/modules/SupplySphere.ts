import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const SupplySphereModule = buildModule("SupplySphereModule", (m) => {
  const inr = m.contract("INR");
  const logistics = m.contract("Logistics");
  const products = m.contract("Products");
  const rawMaterials = m.contract("RawMaterials");
  const services = m.contract("Services");

  const supplyChain = m.contract(
    "SupplyChain",
    [logistics, rawMaterials, services],
    {
      after: [logistics, rawMaterials, services],
    }
  );

  const supplySphere = m.contract(
    "SupplySphere",
    [inr, logistics, products, rawMaterials, services, supplyChain],
    {
      after: [inr, logistics, products, rawMaterials, services, supplyChain],
    }
  );

  return { supplySphere };
});

export default SupplySphereModule;
