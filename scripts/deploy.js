// npx hardhat run scripts/deploy.js --network local
// npx hardhat verify --constructor-args arguments.js --network goerli 0x26f2e0dEAE57b33bFEc2DCD958d04b154e69f405
// npx hardhat verify --network avalanche 0xa49f2a936770eb6ce5D94A455D9598B6cbbec058

const { ethers, upgrades } = require('hardhat');

function tokens(n) {
  return ethers.utils.parseUnits(n, '18');
}

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());
  
    /* ******** Mainnet(FxCore) ******** */
    // const owner = "0x4e3DA49cc22694D53F4a71e4d4BfdFB2BF272887"
    // const governor = "0x4e3DA49cc22694D53F4a71e4d4BfdFB2BF272887"
    // const asset = "0x0000000000000000000000000000000000000000"
    // const reward = "0xc8B4d3e67238e38B20d38908646fF6F4F48De5EC"

    // const stFX= "0x5c24B402b4b4550CF94227813f3547B94774c1CB"
    // const vest= "0x37f716f6693EB2681879642e38BbD9e922A53CDf"

    // const treasury= "0xe48C3eA37D4956580799d90a4601887d77A57d55"
    // const distributor= "0xea505C49B43CD0F9Ed3b40D77CAF1e32b0097328"
    // const multicall= "0xF5E657e315d8766e0841eE83DeEE05aa836Cc8ce"

    /* ******** Testnet(Fuji) ******** */

    // const owner = "0xfe6e9353000a31B9C87F4EAE411C89b1E355Ba50"
    // const governor = "0xfe6e9353000a31B9C87F4EAE411C89b1E355Ba50"
    // const asset = "0x0000000000000000000000000000000000000000"

    const stFX = "0x5aF7AC9DfE8C894E88a197033E550614f2214665"
    // const vest= "0x8E1D972703c0BbE65cbBa42bd75D0Eb41B8397b5"
    // const treasury= "0x1dB21fF54414f62FD65D98c6D5FEdCe6C07CeF10"
    // const reward = "0x28630568bC33Ead4f4A48c0637Dae30aC1114332"


    /* ******** Testnet(Dev) ******** */

    // const owner = "0xfe6e9353000a31B9C87F4EAE411C89b1E355Ba50"
    // const governor = "0xfe6e9353000a31B9C87F4EAE411C89b1E355Ba50"
    // const asset = "0x0000000000000000000000000000000000000000"

    // const stFX= "0x18D094D43140Aaa9BaD82dd08d2dDDa8a6239777"
    // const vest= "0x61f4139abbEB9Af11B9c07FBa862E48e823294CA"
    // const treasury= "0xF47cB2369aa34B624c0De2008308e775E821F585"
    // const distributor= "0x41c4115d5aCDff238eefCa106402Da97bD6DEe77"
    // const reward = "0x18D094D43140Aaa9BaD82dd08d2dDDa8a6239777"

    const owner = "0x4e3DA49cc22694D53F4a71e4d4BfdFB2BF272887"
    const dummy = "0x0000000000000000000000000000000000000000"


// ################################################################################################################################################################


      /*****************************************************
       ***************** Deploy EsBAVA *********************
      *****************************************************/

      // const EsBAVA = await ethers.getContractFactory("EsBAVA");
      // const esBAVA = await upgrades.deployProxy(EsBAVA, [owner, dummy, dummy, dummy], {kind: "uups", timeout: '0', pollingInterval: '1000'});
      
      // // await esBAVA.waitForDeployment();
      // console.log("Contract address:", esBAVA.address);
  

    /*****************************************************
     ***************** Deploy Vester ********************
    *****************************************************/
     
    //  const bavaFxCore   = "0xc8b4d3e67238e38b20d38908646ff6f4f48de5ec"
    //  const esBAVAFxCore = "0x4dE4a1AC6Adf86E492Cf36084B7d92B349b95fa3"
    
    //  const bavaDhouby   = "0xc7e56EEc629D3728fE41baCa2f6BFc502096f94E"
    //  const esBAVADhouby = "0xd00D29C1f5587cbbF483DAE889391b702adcD29F"
    
    //  const Vester = await ethers.getContractFactory("Vester");
    // //  const vester = await upgrades.upgradeProxy("0x41c4115d5aCDff238eefCa106402Da97bD6DEe77", Vester, {kind: "uups", timeout: '0', pollingInterval: '1000'});
    //  const vester = await upgrades.deployProxy(Vester, ["Vested BAVA", "veBAVA", "94608000", esBAVAFxCore, bavaFxCore, owner, owner], {kind: "uups", timeout: '0', pollingInterval: '1000'});
    
    // //  await vester.waitForDeployment();
    //  console.log("Contract address:", vester.address);





    // ============ Deploy StakeFXVault ============

    const StakeFXVault = await ethers.getContractFactory("StakeFXVaultV3");
    const stakeFXVault = await upgrades.upgradeProxy(stFX, StakeFXVault, {kind: "uups", timeout: '0', pollingInterval: '1000'});
    // // // const stakeFXVault = await upgrades.deployProxy(StakeFXVault, [asset, owner, governor], {kind: "uups", timeout: '0', pollingInterval: '1000'});
    await stakeFXVault.deployed();

    // await stakeFXVault.addValidator("fxvaloper17w0adeg64ky0daxwd2ugyuneellmjgnx3uhcc3", "1000")
    // await stakeFXVault.addValidator("fxvaloper1as2rwvnayy30pzjy7aw35dcsja6g98nd87r8vp", "1000")  // European University Cyprus
    // await stakeFXVault.addValidator("fxvaloper1ms606vz2zrxw7752y5ae8z4zyp52ajjacv9qyd", "1000")  // Miami
    // await stakeFXVault.addValidator("fxvaloper19psvqem8jafc5ydg4cnh0t2m04ngw9gfqkeceu", "1000")  // Blindgotchi
    // await stakeFXVault.addValidator("", "200")
    
    // await stakeFXVault.addValidator("fxvaloper1t67ryvnqmnud5g3vpmck00l3umelwkz7huh0s3", "1000")
    // await stakeFXVault.addValidator("fxvaloper1etzrlsszsm0jaj4dp5l25vk3p4w0x4ntl64hlw", "2000")
    // await stakeFXVault.addValidator("fxvaloper1lf3q4vnj94wsc2dtllytrkrsjgwx99yhy50x2x", "500")
    // await stakeFXVault.addValidator("fxvaloper1v65jk0gvzqdghcclldex08cddc38dau6zty3j5", "600")
    // await stakeFXVault.addValidator("fxvaloper158gmj69jpfsrvee3a220afjs952p4m6kltc67h", "1200")
    // await stakeFXVault.addValidator("fxvaloper1sfw4q2uj8ag79usl562u5wz2rwgzavs0fw4tr2", "200")
    console.log("Contract address:", stakeFXVault.address);

    // ============ Deploy FXFeesTreasury ============

    // const FXFeesTreasury = await ethers.getContractFactory("FeeTreasury");
    // // const fxFeesTreasury = await upgrades.upgradeProxy(treasury, FXFeesTreasury, {kind: "uups", timeout: '0', pollingInterval: '1000'});
    // const fxFeesTreasury = await upgrades.deployProxy(FXFeesTreasury, [], {kind: "uups", timeout: '0', pollingInterval: '1000'});
    // await fxFeesTreasury.deployed();

    // console.log("Contract address:", fxFeesTreasury.address);

    // ============ Deploy VestedFX ============

    // const VestedFX = await ethers.getContractFactory("VestedFX");
    // // const vestedFX = await upgrades.upgradeProxy(vest, VestedFX, {kind: "uups", timeout: '0', pollingInterval: '1000'});
    // const vestedFX = await upgrades.deployProxy(VestedFX, [stFX, treasury], {kind: "uups", timeout: '0', pollingInterval: '1000'});
    // await vestedFX.deployed();
    
    // console.log("Contract address:", vestedFX.address);


    // ============ Deploy RewardDistributor ============

    // const RewardDistributor = await ethers.getContractFactory("RewardDistributor");
    // const rewardDistributor = await upgrades.upgradeProxy("0x5ef13FBa677536Fd98C1c98E45D1201774feCC02", RewardDistributor, {kind: "uups", timeout: '0', pollingInterval: '1000'});
    // // const rewardDistributor = await upgrades.deployProxy(RewardDistributor, [reward, stFX, owner, owner], {kind: "uups", timeout: '0', pollingInterval: '1000'});
    // // await rewardDistributor.deployed();

    // console.log("Contract address:", rewardDistributor.address);

    // ============ Deploy MultiCall ============

    // const MultiCall = await ethers.getContractFactory("MultiCall");
    // const multiCall = await upgrades.upgradeProxy("0xF5E657e315d8766e0841eE83DeEE05aa836Cc8ce", MultiCall, {kind: "uups", timeout: '0', pollingInterval: '1000'});
    // // const multiCall = await upgrades.deployProxy(MultiCall, [stFX], {kind: "uups", timeout: '0', pollingInterval: '1000'});
    // await multiCall.deployed();

    // console.log("Contract address:", multiCall.address);
    


    /************** Setup ***************/
    // const stFX= "0x5c24B402b4b4550CF94227813f3547B94774c1CB"
    // const vest= "0x37f716f6693EB2681879642e38BbD9e922A53CDf"
    // const treasury= "0xe48C3eA37D4956580799d90a4601887d77A57d55"
    // const distributor= "0xea505C49B43CD0F9Ed3b40D77CAF1e32b0097328"
    // const multicall= "0xF5E657e315d8766e0841eE83DeEE05aa836Cc8ce"

    // const stakeFXVault = await ethers.getContractAt("StakeFXVaultV2", stFX);
    // const fxFeesTreasury = await ethers.getContractAt("FeeTreasury", treasury);
    // const rewardDistributor = await ethers.getContractAt("RewardDistributor", distributor);

    // await stakeFXVault.updateConfigs(tokens("1"),tokens("1000000"),tokens("10"),tokens("10"));
    // await stakeFXVault.updateFees("690","10","50");

    // await stakeFXVault.addValidator("fxvaloper1a73plz6w7fc8ydlwxddanc7a239kk45jnl9xwj", "1000") // Singapore
    // await stakeFXVault.addValidator("fxvaloper1srkazumnkle6uzmdvqq68df9gglylp3pkhuwna", "1000") // Litecoin

    // await stakeFXVault.updateVestedFX(vest);
    // await stakeFXVault.updateFeeTreasury(treasury);
    // await stakeFXVault.updateDistributor(distributor);

    // await stakeFXVault.grantRole("0x4f574e45525f524f4c4500000000000000000000000000000000000000000000", "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266")
    // await stakeFXVault.grantRole("0x4f50455241544f525f524f4c4500000000000000000000000000000000000000", "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266")
    // await stakeFXVault.grantRole("0x474f5645524e4f525f524f4c4500000000000000000000000000000000000000", "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266")
    // console.log("Contract address:", stakeFXVault.address);
    // const data = [] = await stakeFXVault.getVaultConfigs();
    // console.log(data)
    // await stakeFXVault.stake({value: tokens("0.1")});
    
    // await fxFeesTreasury.updateVestedFX(vest);
    // console.log("Done0");

    // await rewardDistributor.updateLastDistributionTime();
    // await rewardDistributor.setTokensPerInterval("0")

    // console.log("Done1");
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });