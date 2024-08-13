const { StakeFXVaultV2Address, WFXAddress, FXAddress } = require("../utils/constant");
const { expect } = require("chai");

describe("RecoverToken", () => {
  async function loadContractFixture() {
    const stFX = await ethers.getContractAt(
      "StakeFXVaultV2",
      StakeFXVaultV2Address
    );
    const signers = await ethers.getSigners();
    const owner = signers.slice(-1)[0];
    const notOwners = signers.slice(0, -1);
    return { stFX, owner, notOwners };
  }
  it("Owner (other token address)", async () => {
    const { stFX, owner, notOwners } = await loadContractFixture();
    const amount = ethers.utils.parseEther("1");

    for (const notOwner of notOwners) {
        await stFX.connect(owner).recoverToken(WFXAddress, amount, notOwner.address);
    }
  })
  it("Owner (FX token address)", async () => {
    const { stFX, owner, notOwners } = await loadContractFixture();
    const amount = ethers.utils.parseEther("1");

    for (const notOwner of notOwners) {
        await stFX.connect(owner).recoverToken(FXAddress, amount, notOwner.address);
    }
  })
  it("Not owner (other token address)", async () => {
    const { stFX, notOwners } = await loadContractFixture();
    const amount = ethers.utils.parseEther("1");

    for (let i = 0; i < notOwners.length; i++) {
        let notOwner = notOwners[i];
        let value = notOwners.length - i - 1;
        await expect(
            stFX.connect(notOwner).callStatic.recoverToken(WFXAddress, amount, notOwners[value].address)
          ).rejectedWith(Error, `AccessControl`);
    }
  })
  it("Not owner (FX token address)", async () => {
    const { stFX, notOwners } = await loadContractFixture();
    const amount = ethers.utils.parseEther("1");

    for (let i = 0; i < notOwners.length; i++) {
        let notOwner = notOwners[i];
        let value = notOwners.length - i - 1;
        await expect(
            stFX.connect(notOwner).callStatic.recoverToken(FXAddress, amount, notOwners[value].address)
          ).rejectedWith(Error, `AccessControl`);
    }
  })
});