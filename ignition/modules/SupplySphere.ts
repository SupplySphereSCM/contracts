import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import INRModule from "./INR";

const SupplySphereModule = buildModule("SupplySphereModule", (m) => {
  const supplySphere = m.contract("SupplySphere", [
    "0xa818d81E54b927AE6E5bA510434820cd3e9eB02d",
  ]);

  return { supplySphere };
});

export default SupplySphereModule;
