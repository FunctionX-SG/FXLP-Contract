// npx hardhat run scripts/deploy.js --network fxTestnet
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


    /* ******** Testnet(Fuji) ******** */ 

    const owner = "0xfe6e9353000a31B9C87F4EAE411C89b1E355Ba50"
    const governor = "0xfe6e9353000a31B9C87F4EAE411C89b1E355Ba50"
    const asset = "0x0000000000000000000000000000000000000000"

    const vault= "0x5aF7AC9DfE8C894E88a197033E550614f2214665"
    const vest= "0xEe541f260C9fa4bFED73fF97C1dfB0483A684259"
    const treasury= "0x1dB21fF54414f62FD65D98c6D5FEdCe6C07CeF10"
    const reward = "0x28630568bC33Ead4f4A48c0637Dae30aC1114332"

    const start = new Date();
    const startTimeStamp = (parseInt(start.getTime()/1000) + 60).toString()
    console.log(start,startTimeStamp)    


    // // ============ Deploy StakeFXVault ============

    const StakeFXVault = await ethers.getContractFactory("StakeFXVault");
    const stakeFXVault = await upgrades.upgradeProxy(vault, StakeFXVault, {kind: "uups", timeout: '0', pollingInterval: '1000'});
    // const stakeFXVault = await upgrades.deployProxy(StakeFXVault, [asset, owner, governor], {kind: "uups", timeout: '0', pollingInterval: '1000'});
    // await stakeFXVault.deployed();

    // await stakeFXVault.updateConfigs(tokens("1"),tokens("1000000"),tokens("30"),tokens("30"));
    // await stakeFXVault.updateFees("100","50","50");
    
    // await stakeFXVault.addValidator("fxvaloper1t67ryvnqmnud5g3vpmck00l3umelwkz7huh0s3", "1000")
    // await stakeFXVault.addValidator("fxvaloper1etzrlsszsm0jaj4dp5l25vk3p4w0x4ntl64hlw", "2000")
    // await stakeFXVault.addValidator("fxvaloper1lf3q4vnj94wsc2dtllytrkrsjgwx99yhy50x2x", "500")
    // await stakeFXVault.addValidator("fxvaloper1v65jk0gvzqdghcclldex08cddc38dau6zty3j5", "600")
    // await stakeFXVault.addValidator("fxvaloper158gmj69jpfsrvee3a220afjs952p4m6kltc67h", "1200")
    // await stakeFXVault.addValidator("fxvaloper1sfw4q2uj8ag79usl562u5wz2rwgzavs0fw4tr2", "200")
    console.log("Contract address:", stakeFXVault.address);

    // // ============ Deploy VestedFX ============

    const VestedFX = await ethers.getContractFactory("VestedFX");
    const vestedFX = await upgrades.upgradeProxy(vest, VestedFX, {kind: "uups", timeout: '0', pollingInterval: '1000'});
    // const vestedFX = await upgrades.deployProxy(VestedFX, [vault], {kind: "uups", timeout: '0', pollingInterval: '1000'});
    // await vestedFX.deployed();
    
    console.log("Contract address:", vestedFX.address);


    // // ============ Deploy FXFeesTreasury ============

    // const FXFeesTreasury = await ethers.getContractFactory("FeeTreasury");
    // const fxFeesTreasury = await upgrades.deployProxy(FXFeesTreasury, [], {kind: "uups", timeout: '0', pollingInterval: '1000'});
    // await fxFeesTreasury.deployed();

    // console.log("Contract address:", fxFeesTreasury.address);

    // ============ Deploy RewardDistributor ============

    // const RewardDistributor = await ethers.getContractFactory("RewardDistributor");
    // const rewardDistributor = await upgrades.upgradeProxy("0x5ef13FBa677536Fd98C1c98E45D1201774feCC02", RewardDistributor, {kind: "uups", timeout: '0', pollingInterval: '1000'});
    // const rewardDistributor = await upgrades.deployProxy(RewardDistributor, [reward, stakeFXVault.address, owner, owner], {kind: "uups", timeout: '0', pollingInterval: '1000'});
    // await rewardDistributor.deployed();

    // console.log("Contract address:", rewardDistributor.address);


    /************** Setup ***************/
    // const stakeFXVault = await ethers.getContractAt("StakeFXVault", vault);
    // const fxFeesTreasury = await ethers.getContractAt("FeeTreasury", treasury);
    // await stakeFXVault.updateVestedFX(vestedFX.address);
    // await fxFeesTreasury.updateVestedFX(vestedFX.address);

    // await stakeFXVault.updateFeeTreasury(fxFeesTreasury.address);
    // await stakeFXVault.updateDistributor(rewardDistributor.address);
    // console.log("Done0");

    // await rewardDistributor.updateLastDistributionTime();
    // await rewardDistributor.setTokensPerInterval("1000000000000000")

    // console.log("Done1");

    // const testTokenContract = await ethers.getContractAt("StakeFXVault", reward);
    // await testTokenContract.transfer(rewardDistributor.address, tokens("10000000"));

    // console.log("Done2");

    // await stakeFXVault.stake().send({ value: tokens("10000") });

    // console.log("Done3");

    // await rewardDistributor.updateRewardToken("0x88fd0beFa3C762C48BC695D8a90569936B73D22d");
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });

    // Contract address: 0x5aF7AC9DfE8C894E88a197033E550614f2214665
    // Contract address: 0xEe541f260C9fa4bFED73fF97C1dfB0483A684259
    // Contract address: 0x1dB21fF54414f62FD65D98c6D5FEdCe6C07CeF10
    // Contract address: 0x5ef13FBa677536Fd98C1c98E45D1201774feCC02