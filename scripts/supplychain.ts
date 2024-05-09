import hre from "hardhat";

async function main() {
  const Token = await hre.viem.deployContract("INR");
  const SupplySphere = await hre.viem.deployContract("SupplySphere", [
    Token.address,
  ]);

  console.log("Transporter Role: ", await SupplySphere.read.TRANSPORTER_ROLE());
  console.log("Seller Role: ", await SupplySphere.read.SELLER_ROLE());
  console.log(
    "Manufacturer Role: ",
    await SupplySphere.read.MANUFACTURER_ROLE()
  );
  console.log("Retailer Role: ", await SupplySphere.read.RETAILER_ROLE());
}

main()
  .then(() => process.exit())
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
