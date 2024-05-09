import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { expect } from "chai";
import hre from "hardhat";

describe("Logistics", function () {
  async function deployLogistics() {
    const [owner] = await hre.viem.getWalletClients();

    const logistics = await hre.viem.deployContract("Logistics");
    const publicClient = await hre.viem.getPublicClient();

    return {
      owner,
      logistics,
      publicClient,
    };
  }

  it("Should add logistics", async function () {
    const { logistics } = await loadFixture(deployLogistics,);

    const { result } = await logistics.simulate.addLogistics([
      "VRL",
      BigInt(100),
      BigInt(200),
      BigInt(300),
    ]);

    const hash = await logistics.write.addLogistics([
      "VRL",
      BigInt(100),
      BigInt(200),
      BigInt(300),
    ]);

    await (
      await hre.viem.getPublicClient()
    ).waitForTransactionReceipt({ hash });

    const logistic = await logistics.read.getLogistic([BigInt(result)]);

    expect(logistic.name).to.equal("VRL");
    expect(logistic.priceWithinState).to.equal(BigInt(100));
    expect(logistic.priceInterState).to.equal(BigInt(200));
    expect(logistic.priceInternationl).to.equal(BigInt(300));
  });

  it("Should get All logistics", async function () {
    const { logistics, owner } = await loadFixture(deployLogistics);

    await logistics.write.addLogistics([
      "VRL",
      BigInt(100),
      BigInt(200),
      BigInt(300),
    ]);

    const allLogistics = await logistics.read.getAllLogistics();
    expect(allLogistics).to.have.lengthOf(1);
  });

  it("Should delete Logistic", async function () {
    const { logistics } = await loadFixture(deployLogistics);
    const { result } = await logistics.simulate.addLogistics([
      "VRL",
      BigInt(100),
      BigInt(200),
      BigInt(300),
    ]);

    await logistics.write.addLogistics([
      "VRL",
      BigInt(100),
      BigInt(200),
      BigInt(300),
    ]);

    await logistics.write.removeLogistic([result]);
    const allLogistics = await logistics.read.getAllLogistics();
    expect(allLogistics).to.have.lengthOf(0);
  });
});
