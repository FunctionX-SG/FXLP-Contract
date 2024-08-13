const { StakeFXVaultV2Address } = require("../utils/constant");
const { expect } = require("chai");

describe("UpdateVestedFX", () => {
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
    const { stFX, authorizedUser, notAuthorizedUsers } = await loadContractFixture();

    for (const notAuthorizedUser of notAuthorizedUsers) {
        await stFX.connect(authorizedUser).callStatic.updateVestedFX(notAuthorizedUser.address);
    }
  });
  it("Not authorized user", async () => {
    const { stFX, notAuthorizedUsers } = await loadContractFixture();

    for (let i = 0; i < notAuthorizedUsers.length; i++) {
        let notAuthUser = notAuthorizedUsers[i];
        let value = notAuthorizedUsers.length - i - 1;
        await expect(
            stFX.connect(notAuthUser).callStatic.updateVestedFX(notAuthorizedUsers[value].address)
          ).rejectedWith(Error, `AccessControl`);
    }
  })
});