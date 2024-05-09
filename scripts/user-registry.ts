import hre from "hardhat";

async function main() {
  const userRegistry = await hre.viem.deployContract("UserRegistry");

  console.log("Users", await userRegistry.read.getAllUsers());

  let trxHash;

  console.log("Adding user 1 (Krtin, 21);");
  trxHash = await userRegistry.write.addUser(["Krtin", BigInt(21)]);
  console.log("Trx Hash: ", trxHash);

  console.log("Adding user 2 (Ishan, 18);");
  trxHash = await userRegistry.write.addUser(["Ishan", BigInt(18)]);
  console.log("Trx Hash: ", trxHash);

  console.log("Adding user 3 (Namira, 23);");
  trxHash = await userRegistry.write.addUser(["Namira", BigInt(23)]);
  console.log("Trx Hash: ", trxHash);

  console.log("Users", await userRegistry.read.getAllUsers());
}

main()
  .then(() => process.exit())
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
