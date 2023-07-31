// npx hardhat run test/test.js --network fxTestnet
// npx hardhat verify --constructor-args arguments.js --network goerli 0x26f2e0dEAE57b33bFEc2DCD958d04b154e69f405
// npx hardhat verify --network avalanche 0xa49f2a936770eb6ce5D94A455D9598B6cbbec058

const { ethers, waffle, upgrades } = require('hardhat');




function tokensToWei(n) {
  return ethers.utils.parseUnits(n, '18');
}

function tokensToEther(n) {
  return ethers.utils.formatUnits(n, '18');
}

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);
    // console.log("Account balance:", (await deployer.getBalance()).toString());
  
    /* ******** Mainnet(FxCore) ******** */ 


    /* ******** Testnet(Fuji) ******** */ 


    const precompileStaking = "0x0000000000000000000000000000000000001003"

    const stFX = "0x5aF7AC9DfE8C894E88a197033E550614f2214665"
    const VestedFX = "0x8E1D972703c0BbE65cbBa42bd75D0Eb41B8397b5"
    const feeTreasury = "0x1dB21fF54414f62FD65D98c6D5FEdCe6C07CeF10"
    const multicall = "0x9A434d8253BC8A55e3e2de19275A71eA8Be63Cd4"

    const val0 = "fxvaloper1t67ryvnqmnud5g3vpmck00l3umelwkz7huh0s3"
    const val1 = "fxvaloper1etzrlsszsm0jaj4dp5l25vk3p4w0x4ntl64hlw"
    const val2 = "fxvaloper1lf3q4vnj94wsc2dtllytrkrsjgwx99yhy50x2x"
    const val3 = "fxvaloper1v65jk0gvzqdghcclldex08cddc38dau6zty3j5"
    const val4 = "fxvaloper158gmj69jpfsrvee3a220afjs952p4m6kltc67h"
    const val5 = "fxvaloper1sfw4q2uj8ag79usl562u5wz2rwgzavs0fw4tr2"

    // ============ Deploy PrecompileStaking ============

    // const precompileStakingContract = await ethers.getContractAt("IPrecompileStaking", precompileStaking);

    // const delegation0 = await precompileStakingContract.delegation(val0,stFX);
    // const delegation1 = await precompileStakingContract.delegation(val1,stFX);
    // const delegation2 = await precompileStakingContract.delegation(val2,stFX);
    // const delegation3 = await precompileStakingContract.delegation(val3,stFX);
    // const delegation4 = await precompileStakingContract.delegation(val4,stFX);
    // const delegation5 = await precompileStakingContract.delegation(val5,stFX);

    const balanceInWei0 = await ethers.provider.getBalance(stFX);
    // const balanceInWei1 = await ethers.provider.getBalance(VestedFX);
    // const balanceInWei2 = await ethers.provider.getBalance(feeTreasury);
    console.log("Account balance:", tokensToEther(balanceInWei0));
    
    // console.log(tokensToEther(delegation0[1].toString()))
    // console.log(tokensToEther(delegation1[1].toString()))
    // console.log(tokensToEther(delegation2[1].toString()))
    // console.log(tokensToEther(delegation3[1].toString()))
    // console.log(tokensToEther(delegation4[1].toString()))
    // console.log(tokensToEther(delegation5[1].toString()))

    const multicallContract = await ethers.getContractAt("MultiCall", multicall);
    const allDelegation = await multicallContract.getAllValidatorDelegation();

    console.log(tokensToEther(allDelegation[0][2].toString()))
    console.log(tokensToEther(allDelegation[1][2].toString()))
    console.log(tokensToEther(allDelegation[2][2].toString()))
    console.log(tokensToEther(allDelegation[3][2].toString()))
    console.log(tokensToEther(allDelegation[4][2].toString()))
    console.log(tokensToEther(allDelegation[5][2].toString()))
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });

