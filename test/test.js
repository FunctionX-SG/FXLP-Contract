// npx hardhat run test/test.js --network fxTestnet
// npx hardhat verify --constructor-args arguments.js --network goerli 0x26f2e0dEAE57b33bFEc2DCD958d04b154e69f405
// npx hardhat verify --network avalanche 0xa49f2a936770eb6ce5D94A455D9598B6cbbec058

const { ethers, waffle, upgrades } = require('hardhat');




function tokens(n) {
  return ethers.utils.parseUnits(n, '18');
}

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);
    // console.log("Account balance:", (await deployer.getBalance()).toString());
  
    /* ******** Mainnet(FxCore) ******** */ 


    /* ******** Testnet(Fuji) ******** */ 


    const precompileStaking = "0x0000000000000000000000000000000000001003"

    const stFX = "0x465A52C6bb4093eb696dcb71015CA8cEf344340E"
    const VestedFX = "0xB0B8922Ac43d7789CFc4F5F35e330E05068E00F8"
    const feeTreasury = "0xED3e5E36cD527B1Dc07AE84662494d92A7c8F7CA"

    const val0 = "fxvaloper1t67ryvnqmnud5g3vpmck00l3umelwkz7huh0s3"
    const val1 = "fxvaloper1etzrlsszsm0jaj4dp5l25vk3p4w0x4ntl64hlw"
    const val2 = "fxvaloper1lf3q4vnj94wsc2dtllytrkrsjgwx99yhy50x2x"
    const val3 = "fxvaloper1v65jk0gvzqdghcclldex08cddc38dau6zty3j5"
    const val4 = "fxvaloper158gmj69jpfsrvee3a220afjs952p4m6kltc67h"
    const val5 = "fxvaloper1sfw4q2uj8ag79usl562u5wz2rwgzavs0fw4tr2"

    // ============ Deploy PrecompileStaking ============

    const precompileStakingContract = await ethers.getContractAt("IPrecompileStaking", precompileStaking);

    const delegation0 = await precompileStakingContract.delegation(val0,stFX);
    const delegation1 = await precompileStakingContract.delegation(val1,stFX);
    const delegation2 = await precompileStakingContract.delegation(val2,stFX);
    const delegation3 = await precompileStakingContract.delegation(val3,stFX);
    const delegation4 = await precompileStakingContract.delegation(val4,stFX);
    const delegation5 = await precompileStakingContract.delegation(val5,stFX);

    const balanceInWei0 = await ethers.provider.getBalance(stFX);
    const balanceInWei1 = await ethers.provider.getBalance(VestedFX);
    const balanceInWei2 = await ethers.provider.getBalance(feeTreasury);
    console.log("Account balance:", balanceInWei0, balanceInWei1, balanceInWei2);
    
    console.log(delegation0, delegation1, delegation2, delegation3, delegation4, delegation5)

  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });

