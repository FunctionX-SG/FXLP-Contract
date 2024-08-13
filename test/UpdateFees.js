const { StakeFXVaultV2Address } = require("../utils/constant");
const { expect } = require("chai");

describe("UpdateFees", () => {
  async function loadContractFixture() {
    const stFX = await ethers.getContractAt(
      "StakeFXVaultV2",
      StakeFXVaultV2Address
    );
    const signers = await ethers.getSigners();
    const authorizedUser = signers.slice(-1)[0];
    const notAuthorizedUsers = signers.slice(0, -1);
    return { stFX, authorizedUser, notAuthorizedUsers };
  }
  it("Authorized user", async () => {
    const { stFX, authorizedUser } = await loadContractFixture();
    await stFX.connect(authorizedUser).callStatic.updateFees(1, 1, 1);
  });
  it("Not authorized user", async () => {
    const { stFX, notAuthorizedUsers } = await loadContractFixture();

    for (const notAuthUser of notAuthorizedUsers) {
      await expect(
        stFX.connect(notAuthUser).callStatic.updateFees(1, 1, 1)
      ).rejectedWith(Error, `AccessControl`);
    }
  });


});