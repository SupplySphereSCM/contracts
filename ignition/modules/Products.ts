import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const ProductsModule = buildModule("ProductsModule", (m) => {
  const products = m.contract("Products");

  return { products };
});

export default ProductsModule;
