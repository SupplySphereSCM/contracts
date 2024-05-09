import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import INRModule from "./INR";

const SupplySphereModule = buildModule("SupplySphereModule", (m) => {
  const supplySphere = m.contract("SupplySphere", [
    "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
  ]);

  return { supplySphere };
});

export default SupplySphereModule;
