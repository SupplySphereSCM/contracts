import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { expect } from "chai";
import hre from "hardhat";

describe("SupplySphere", function () {
  async function deploySupplySphere() {
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
    const logistics = await hre.viem.deployContract("Logistics");
    const products = await hre.viem.deployContract("Products");
    const rawMaterials = await hre.viem.deployContract("RawMaterials");
    const services = await hre.viem.deployContract("Services");
    const supplyChain = await hre.viem.deployContract("SupplyChain", [
      logistics.address,
      rawMaterials.address,
      services.address,
    ]);
    const supplysphere = await hre.viem.deployContract("SupplySphere", [
      inr.address,
      logistics.address,
      products.address,
      rawMaterials.address,
      services.address,
      supplyChain.address,
    ]);

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

    const SELLER_ROLE = await supplysphere.read.SELLER_ROLE();
    const TRANSPORTER_ROLE = await supplysphere.read.TRANSPORTER_ROLE();
    const MANUFACTURER_ROLE = await supplysphere.read.MANUFACTURER_ROLE();
    const RETAILER_ROLE = await supplysphere.read.RETAILER_ROLE();

    return {
      testClient,
      publicClient,
      //
      TRANSPORTER_ROLE,
      SELLER_ROLE,
      MANUFACTURER_ROLE,
      RETAILER_ROLE,
      //
      inr,
      logistics,
      products,
      rawMaterials,
      services,
      supplyChain,
      supplysphere,
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

  describe("Roles", function () {
    it("Should assign roles correctly", async function () {
      const {
        supplysphere,
        seller1,
        transporter1,
        manufacturer1,
        SELLER_ROLE,
        TRANSPORTER_ROLE,
        MANUFACTURER_ROLE,
      } = await loadFixture(deploySupplySphere);

      // Register roles
      await supplysphere.write.registerUser([SELLER_ROLE], {
        account: seller1.account,
      });
      await supplysphere.write.registerUser([TRANSPORTER_ROLE], {
        account: transporter1.account,
      });
      await supplysphere.write.registerUser([MANUFACTURER_ROLE], {
        account: manufacturer1.account,
      });

      // Check roles
      expect(
        await supplysphere.read.hasRole([SELLER_ROLE, seller1.account.address])
      ).to.be.true;
      expect(
        await supplysphere.read.hasRole([
          TRANSPORTER_ROLE,
          transporter1.account.address,
        ])
      ).to.be.true;
      expect(
        await supplysphere.read.hasRole([
          MANUFACTURER_ROLE,
          manufacturer1.account.address,
        ])
      ).to.be.true;
    });
  });

  describe("Logistics", function () {
    it("Should add logistic only by transporter role", async function () {
      const { TRANSPORTER_ROLE, supplysphere, transporter1 } =
        await loadFixture(deploySupplySphere);

      await supplysphere.write.registerUser([TRANSPORTER_ROLE], {
        account: transporter1.account,
      });

      const { result: logisticsId } = await supplysphere.simulate.addLogistic(
        ["Transport Company", BigInt(1000)],
        { account: transporter1.account.address }
      );

      await supplysphere.write.addLogistic(
        ["Transport Company", BigInt(1000)],
        { account: transporter1.account }
      );
      const logistic = await supplysphere.read.getLogistic([logisticsId]);

      expect(logistic.name).to.equal("Transport Company");
      expect(logistic.price).to.equal(BigInt(1000));
      expect(logistic.owner.toLowerCase()).to.equal(
        transporter1.account.address.toLowerCase()
      );
    });
  });

  describe("Products", function () {
    it("Should add a product only by manufacturer role", async function () {
      const { supplysphere, manufacturer1, MANUFACTURER_ROLE } =
        await loadFixture(deploySupplySphere);

      await supplysphere.write.registerUser([MANUFACTURER_ROLE], {
        account: manufacturer1.account,
      });

      const { result: productId } = await supplysphere.simulate.addProduct(
        ["Product A", BigInt(5000), BigInt(10), BigInt(100)],
        { account: manufacturer1.account.address }
      );

      await supplysphere.write.addProduct(
        ["Product A", BigInt(5000), BigInt(10), BigInt(100)],
        { account: manufacturer1.account }
      );
      const product = await supplysphere.read.getProduct([productId]);

      expect(product.name).to.equal("Product A");
      expect(product.price).to.equal(BigInt(5000));
      expect(product.tax).to.equal(BigInt(10));
      expect(product.quantity).to.equal(BigInt(100));
      expect(product.owner.toLowerCase()).to.equal(
        manufacturer1.account.address.toLowerCase()
      );
    });
  });

  describe("Raw Materials", function () {
    it("Should add raw material only by seller role", async function () {
      const { supplysphere, seller1, SELLER_ROLE } = await loadFixture(
        deploySupplySphere
      );

      await supplysphere.write.registerUser([SELLER_ROLE], {
        account: seller1.account,
      });

      const { result: materialId } = await supplysphere.simulate.addRawMaterial(
        ["Raw Material X", BigInt(2000), BigInt(5), BigInt(50)],
        { account: seller1.account.address }
      );

      await supplysphere.write.addRawMaterial(
        ["Raw Material X", BigInt(2000), BigInt(5), BigInt(50)],
        { account: seller1.account }
      );
      const material = await supplysphere.read.getRawMaterial([materialId]);

      expect(material.name).to.equal("Raw Material X");
      expect(material.price).to.equal(BigInt(2000));
      expect(material.tax).to.equal(BigInt(5));
      expect(material.quantity).to.equal(BigInt(50));
      expect(material.owner.toLowerCase()).to.equal(
        seller1.account.address.toLowerCase()
      );
    });
  });

  describe("Services", function () {
    it("Should add service only by seller role", async function () {
      const { SELLER_ROLE, supplysphere, seller1 } = await loadFixture(
        deploySupplySphere
      );

      await supplysphere.write.registerUser([SELLER_ROLE], {
        account: seller1.account,
      });

      const { result: serviceId } = await supplysphere.simulate.addService(
        ["Service Y", BigInt(1500), BigInt(8), BigInt(30), BigInt(10)],
        { account: seller1.account.address }
      );

      await supplysphere.write.addService(
        ["Service Y", BigInt(1500), BigInt(8), BigInt(30), BigInt(10)],
        { account: seller1.account }
      );
      const service = await supplysphere.read.getService([serviceId]);

      expect(service.name).to.equal("Service Y");
      expect(service.price).to.equal(BigInt(1500));
      expect(service.tax).to.equal(BigInt(8));
      expect(service.quantity).to.equal(BigInt(30));
      expect(service.volume).to.equal(BigInt(10));
      expect(service.owner.toLowerCase()).to.equal(
        seller1.account.address.toLowerCase()
      );
    });
  });

  describe("SupplyChain", function () {
    it("Should create a supply chain only by manufacturer role", async function () {
      const {
        supplysphere,
        manufacturer1,
        MANUFACTURER_ROLE,
        seller1,
        SELLER_ROLE,
        transporter1,
        TRANSPORTER_ROLE,
        owner,
      } = await loadFixture(deploySupplySphere);

      // -----------------------
      await supplysphere.write.registerUser([SELLER_ROLE], {
        account: seller1.account,
      });

      const { result: materialId } = await supplysphere.simulate.addRawMaterial(
        ["Raw Material X", BigInt(2000), BigInt(5), BigInt(50)],
        { account: seller1.account.address }
      );

      await supplysphere.write.addRawMaterial(
        ["Raw Material X", BigInt(2000), BigInt(5), BigInt(50)],
        { account: seller1.account }
      );
      // -----------------------

      await supplysphere.write.registerUser([TRANSPORTER_ROLE], {
        account: transporter1.account,
      });

      const { result: logisticsId } = await supplysphere.simulate.addLogistic(
        ["Transport Company", BigInt(1000)],
        { account: transporter1.account.address }
      );

      await supplysphere.write.addLogistic(
        ["Transport Company", BigInt(1000)],
        { account: transporter1.account }
      );

      // -----------------------

      await supplysphere.write.registerUser([MANUFACTURER_ROLE], {
        account: manufacturer1.account,
      });

      const { result: supplyChainId } =
        await supplysphere.simulate.createSupplyChain(
          [
            "Chain A",
            "Description for Chain A",
            [
              {
                stepType: 0,
                itemId: materialId,
                logisticsId,
                quantity: BigInt(1),
                receiver: manufacturer1.account.address,
              },
            ],
          ],
          { account: manufacturer1.account.address }
        );

      await supplysphere.write.createSupplyChain(
        [
          "Chain A",
          "Description for Chain A",
          [
            {
              stepType: 0,
              itemId: materialId,
              logisticsId,
              quantity: BigInt(1),
              receiver: manufacturer1.account.address,
            },
          ],
        ],
        { account: manufacturer1.account }
      );

      const supplyChain = await supplysphere.read.getSupplyChain([
        supplyChainId,
      ]);

      expect(supplyChain.name).to.equal("Chain A");
      expect(supplyChain.description).to.equal("Description for Chain A");
      expect(supplyChain.owner.toLowerCase()).to.equal(
        manufacturer1.account.address.toLowerCase()
      );
    });
  });

  describe("Fund Release", function () {
    it("Should release funds upon successful completion of steps", async function () {
      const {
        inr,
        supplysphere,
        manufacturer1,
        MANUFACTURER_ROLE,
        seller1,
        seller2,
        SELLER_ROLE,
        transporter1,
        TRANSPORTER_ROLE,
        owner,
      } = await loadFixture(deploySupplySphere);

      // ----------------------- raw material
      await supplysphere.write.registerUser([SELLER_ROLE], {
        account: seller1.account,
      });
      await supplysphere.write.registerUser([SELLER_ROLE], {
        account: seller2.account,
      });

      const { result: materialId } = await supplysphere.simulate.addRawMaterial(
        ["Raw Material X", BigInt(2000), BigInt(5), BigInt(50)],
        { account: seller1.account.address }
      );

      await supplysphere.write.addRawMaterial(
        ["Raw Material X", BigInt(2000), BigInt(5), BigInt(50)],
        { account: seller1.account }
      );
      // -----------------------  logistics

      await supplysphere.write.registerUser([TRANSPORTER_ROLE], {
        account: transporter1.account,
      });

      const { result: logisticsId } = await supplysphere.simulate.addLogistic(
        ["Transport Company", BigInt(1000)],
        { account: transporter1.account.address }
      );

      await supplysphere.write.addLogistic(
        ["Transport Company", BigInt(1000)],
        { account: transporter1.account }
      );

      // ----------------------- supplychain

      await supplysphere.write.registerUser([MANUFACTURER_ROLE], {
        account: manufacturer1.account,
      });

      const { result: supplyChainId } =
        await supplysphere.simulate.createSupplyChain(
          [
            "Chain A",
            "Description for Chain A",
            [
              {
                stepType: 0,
                itemId: materialId,
                logisticsId,
                quantity: BigInt(1),
                receiver: seller2.account.address,
              },
            ],
          ],
          { account: manufacturer1.account.address }
        );

      await supplysphere.write.createSupplyChain(
        [
          "Chain A",
          "Description for Chain A",
          [
            {
              stepType: 0,
              itemId: materialId,
              logisticsId,
              quantity: BigInt(1),
              receiver: seller2.account.address,
            },
          ],
        ],
        { account: manufacturer1.account }
      );

      let supplyChain = await supplysphere.read.getSupplyChain([supplyChainId]);

      // manufacturer Approve INR transfers for the supply sphere

      await inr.write.approve(
        [supplysphere.address, BigInt(supplyChain.totalFundedAmount)],
        { account: manufacturer1.account }
      );

      expect(
        await inr.read.allowance([
          manufacturer1.account.address,
          supplysphere.address,
        ])
      ).to.equal(BigInt(3000));

      // manufacturer should fund the chain

      await supplysphere.write.fundChain([supplyChainId], {
        account: manufacturer1.account,
      });

      supplyChain = await supplysphere.read.getSupplyChain([supplyChainId]);

      expect(supplyChain.isActive).to.be.true;
      expect(supplyChain.isFunded).to.be.true;

      // Confirm steps
      //  step 1
      await supplysphere.write.confirmSender([supplyChainId, BigInt(0)], {
        account: seller1.account,
      });

      supplyChain = await supplysphere.read.getSupplyChain([supplyChainId]);
      expect(supplyChain.steps[0].senderConfirmed).to.be.true;

      //  step 2
      await supplysphere.write.confirmTransporterReceived(
        [supplyChainId, BigInt(0)],
        {
          account: transporter1.account,
        }
      );

      supplyChain = await supplysphere.read.getSupplyChain([supplyChainId]);
      expect(supplyChain.steps[0].transporterReceived).to.be.true;

      //  step 3
      await supplysphere.write.confirmTransporterDelivered(
        [supplyChainId, BigInt(0)],
        {
          account: transporter1.account,
        }
      );

      supplyChain = await supplysphere.read.getSupplyChain([supplyChainId]);
      expect(supplyChain.steps[0].transporterDelivered).to.be.true;

      //  step 4
      await supplysphere.write.confirmReceiver([supplyChainId, BigInt(0)], {
        account: seller2.account,
      });

      supplyChain = await supplysphere.read.getSupplyChain([supplyChainId]);
      expect(supplyChain.steps[0].receiverConfirmed).to.be.true;

      //  manufacturer1 should be deducted
      expect(
        await inr.read.balanceOf([manufacturer1.account.address])
      ).to.be.eq(BigInt(1000000000000 - 3000));
      // seller 1 should be funded
      expect(await inr.read.balanceOf([seller1.account.address])).to.be.eq(
        BigInt(1000000000000 + 2000)
      );
      //transporter 1 should be funded
      expect(await inr.read.balanceOf([transporter1.account.address])).to.be.eq(
        BigInt(1000000000000 + 1000)
      );
    });
  });
});
