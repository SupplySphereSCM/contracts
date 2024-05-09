import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { expect } from "chai";
import hre from "hardhat";

describe("SupplyChain", async function () {
  async function deploySupplyChain() {
    const [
      owner,
      seller1,
      seller2,
      transporter1,
      transporter2,
      manufacturer1,
      manufacturer2,
    ] = await hre.viem.getWalletClients();

    const inr = await hre.viem.deployContract("INR");
    const products = await hre.viem.deployContract("Products");
    const services = await hre.viem.deployContract("Services");
    const supplychain = await hre.viem.deployContract("SupplyChain");

    const testClient = await hre.viem.getTestClient();
    const publicClient = await hre.viem.getPublicClient();

    await inr.write.mint([seller1.account.address, BigInt(1000000000000)]);
    await inr.write.mint([seller2.account.address, BigInt(1000000000000)]);
    await inr.write.mint([transporter1.account.address, BigInt(1000000000000)]);
    await inr.write.mint([transporter2.account.address, BigInt(1000000000000)]);
    await inr.write.mint([
      manufacturer1.account.address,
      BigInt(1000000000000),
    ]);
    await inr.write.mint([
      manufacturer2.account.address,
      BigInt(1000000000000),
    ]);

    // create few products

    return {
      publicClient,
      testClient,
      //
      inr,
      products,
      supplychain,
      services,
      //
      owner,
      seller1,
      seller2,
      transporter1,
      transporter2,
      manufacturer1,
      manufacturer2,
    };
  }

  it("Should create New Supplychain", async function () {
    const { supplychain, seller1, seller2, transporter1 } = await loadFixture(
      deploySupplyChain
    );

    const { result } = await supplychain.simulate.createSupplyChain([
      "Test1",
      "Test1",
      [
        {
          stepType: 0,
          productId: BigInt(1),
          quantity: BigInt(2),
          logisticsCost: BigInt(5),
          serviceCost: BigInt(0),
          sender: seller1.account.address,
          transporter: transporter1.account.address,
          receiver: seller2.account.address,
        },
        {
          stepType: 1,
          productId: BigInt(1),
          quantity: BigInt(3),
          logisticsCost: BigInt(0),
          serviceCost: BigInt(6),
          sender: seller1.account.address,
          transporter: transporter1.account.address,
          receiver: seller2.account.address,
        },
      ],
    ]);

    await supplychain.write.createSupplyChain([
      "Test1",
      "Test1",
      [
        {
          stepType: 0,
          productId: BigInt(1),
          quantity: BigInt(2),
          logisticsCost: BigInt(5),
          serviceCost: BigInt(0),
          sender: seller1.account.address,
          transporter: transporter1.account.address,
          receiver: seller2.account.address,
        },
        {
          stepType: 1,
          productId: BigInt(1),
          quantity: BigInt(3),
          logisticsCost: BigInt(0),
          serviceCost: BigInt(6),
          sender: seller1.account.address,
          transporter: transporter1.account.address,
          receiver: seller2.account.address,
        },
      ],
    ]);

    const chain = await supplychain.read.getSupplyChain([result]);

    expect(chain.name).to.equal("Test1");
    expect(chain.isActive).to.have.false;
    expect(chain.isFunded).to.have.false;
    expect(chain.steps).to.have.lengthOf(2);
    expect(chain.description).to.equal("Test1");
    expect(chain.totalFundedAmount).to.equal(28);
    expect(chain.steps[0].totalCost).to.equal(10);
    expect(chain.steps[1].totalCost).to.equal(18);
  });

  it("Should be able to fund  & be active", async function () {
    const { supplychain, seller1, seller2, transporter1, manufacturer1, inr } =
      await loadFixture(deploySupplyChain);

    const { result } = await supplychain.simulate.createSupplyChain([
      "Test1",
      "Test1",
      [
        {
          stepType: 0,
          productId: BigInt(1),
          quantity: BigInt(2),
          logisticsCost: BigInt(5),
          serviceCost: BigInt(0),
          sender: seller1.account.address,
          transporter: transporter1.account.address,
          receiver: seller2.account.address,
        },
      ],
    ]);

    await manufacturer1.writeContract({
      address: supplychain.address,
      abi: supplychain.abi,
      functionName: "createSupplyChain",
      args: [
        "Test1",
        "Test1",
        [
          {
            stepType: 0,
            productId: BigInt(1),
            quantity: BigInt(2),
            logisticsCost: BigInt(5),
            serviceCost: BigInt(0),
            sender: seller1.account.address,
            transporter: transporter1.account.address,
            receiver: seller2.account.address,
          },
          {
            stepType: 1,
            productId: BigInt(1),
            quantity: BigInt(3),
            logisticsCost: BigInt(0),
            serviceCost: BigInt(6),
            sender: seller1.account.address,
            transporter: transporter1.account.address,
            receiver: seller2.account.address,
          },
        ],
      ],
    });

    let chain = await supplychain.read.getSupplyChain([result]);

    expect(chain.owner.toLowerCase()).to.equals(
      manufacturer1.account.address.toLowerCase()
    );

    await manufacturer1.writeContract({
      address: inr.address,
      abi: inr.abi,
      functionName: "approve",
      args: [supplychain.address, BigInt(chain.totalFundedAmount)],
    });

    await manufacturer1.writeContract({
      address: supplychain.address,
      abi: supplychain.abi,
      functionName: "fundChain",
      args: [result, inr.address],
    });

    chain = await supplychain.read.getSupplyChain([result]);

    expect(chain.isActive).to.be.true;
    expect(chain.isFunded).to.be.true;
  });

  it("Should move the products from sender to receiver & release funds", async function () {
    const { supplychain, seller1, seller2, transporter1, manufacturer1, inr } =
      await loadFixture(deploySupplyChain);
  });
});
