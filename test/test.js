const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("SafeMEME token", function () {
  async function deployTokenFixture() {

    const Token = await ethers.getContractFactory("SafeMEME");
    const [owner, addr1] = await ethers.getSigners();

    const hardhatToken = await Token.deploy();

    await hardhatToken.deployed();

    return { Token, hardhatToken, owner, addr1 };
  }

  describe("Deployment", function () {

    it("Should set msg.sender as owner", async function () {
      const { hardhatToken, owner } = await loadFixture(deployTokenFixture);
      expect(await hardhatToken.owner()).to.equal(owner.address);
    });

    it("Should assign the total supply of tokens to the owner", async function () {
      const { hardhatToken, owner } = await loadFixture(deployTokenFixture);
      const ownerBalance = await hardhatToken.balanceOf(owner.address);
      expect(await hardhatToken.totalSupply()).to.equal(ownerBalance);
    });
  });

  describe("Transactions", function () {
    it("Should transfer tokens between accounts", async function () {
      const { hardhatToken, owner, addr1 } = await loadFixture(deployTokenFixture);
      // Transfer 50 tokens from owner to addr1
      await expect(hardhatToken.transfer(addr1.address, 50))
        .to.changeTokenBalances(hardhatToken, [owner, addr1], [-50, 50]);

      // Transfer 50 tokens from addr1 to owner
      // We use .connect(signer) to send a transaction from another account
      await expect(hardhatToken.connect(addr1).transfer(owner.address, 50))
        .to.changeTokenBalances(hardhatToken, [addr1, owner], [-50, 50]);
    });

    it("Should emit Transfer events", async function () {
      const { hardhatToken, owner, addr1 } = await loadFixture(deployTokenFixture);

      // Transfer 50 tokens from owner to addr1
      await expect(hardhatToken.transfer(addr1.address, 50))
        .to.emit(hardhatToken, "Transfer").withArgs(owner.address, addr1.address, 50)

      // Transfer 50 tokens from addr1 to owner
      // We use .connect(signer) to send a transaction from another account
      await expect(hardhatToken.connect(addr1).transfer(owner.address, 50))
        .to.emit(hardhatToken, "Transfer").withArgs(addr1.address, owner.address, 50)
    });

    it("Should fail when the same address tries to transfer two times in one block", async function () {
      const { hardhatToken, owner, addr1 } = await loadFixture(deployTokenFixture);
    
      await network.provider.send("evm_setAutomine", [false]);
      
      // Transfer 50 tokens from owner to addr1
      const firstTx = await hardhatToken.transfer(addr1.address, 50, {
        gasLimit: 200000
      });

      // Try to send 50 token from owner account again
      const secondTx = await hardhatToken.transfer(addr1.address, 50, {
        gasLimit: 200000
      });
      
      await network.provider.send("evm_mine");
      
      await expect(secondTx)
        .to.be.reverted;
    });
  });
});