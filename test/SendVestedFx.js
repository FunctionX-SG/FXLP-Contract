const { StakeFXVaultV2Address } = require("../utils/constant");
const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("SendVestedFX", () => {
  async function loadContractFixture() {
    const stFX = await ethers.getContractAt(
      "StakeFXVaultV2",
      StakeFXVaultV2Address
    );
    const signers = await ethers.getSigners();
    return { stFX, signers };
  }
  // it("Is vested contract address", async()=>{
  //     const {stFX} = await loadContractFixture()
  //     const stakeAmount = ethers.utils.parseEther("1")
  //     const deployedVestedContractAddress = "0x61f4139abbEB9Af11B9c07FBa862E48e823294CA"
  //     await stFX.connect(deployedVestedContractAddress).callStatic.sendVestedFX(stakeAmount)
  // })
  it("Is not vested contract address", async () => {
    const { stFX, signers } = await loadContractFixture();
    const stakeAmount = ethers.utils.parseEther("1");

    for (const addr of signers) {
      await expect(stFX.connect(addr).callStatic.sendVestedFX(stakeAmount)).rejectedWith(
        Error,
        "Only VestedFX can call"
      );
    }
  });
});