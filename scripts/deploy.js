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

    const vault= "0x465A52C6bb4093eb696dcb71015CA8cEf344340E"
    const vest= "0xf2b4f50dbBee6b54166dE5FB297768fD9286456d"
    // const treasury= "0x9C58851D180Dbc4607d22E338c78D90A09cB3a69"
    const reward = "0xA8848a945c1AFeEdB6E3893cac22F0b460c49B77"

    const start = new Date();
    const startTimeStamp = (parseInt(start.getTime()/1000) + 60).toString()
    console.log(start,startTimeStamp)    


    // ============ Deploy StakeFXVault ============

    // const StakeFXVault = await ethers.getContractFactory("StakeFXVault");
    // // const stakeFXVault = await upgrades.upgradeProxy(vault, StakeFXVault, {kind: "uups", timeout: '0', pollingInterval: '1000'});
    // const stakeFXVault = await upgrades.deployProxy(StakeFXVault, [asset, owner, governor], {kind: "uups", timeout: '0', pollingInterval: '1000'});
    // await stakeFXVault.deployed();

    // await stakeFXVault.updateConfigs(tokens("1"),tokens("10000"),tokens("30"),tokens("30"));
    // await stakeFXVault.updateFees("100","50","50");
    
    // await stakeFXVault.addValidator("fxvaloper1t67ryvnqmnud5g3vpmck00l3umelwkz7huh0s3", "1000")
    // await stakeFXVault.addValidator("fxvaloper1etzrlsszsm0jaj4dp5l25vk3p4w0x4ntl64hlw", "2000")
    // await stakeFXVault.addValidator("fxvaloper1lf3q4vnj94wsc2dtllytrkrsjgwx99yhy50x2x", "500")
    // await stakeFXVault.addValidator("fxvaloper1v65jk0gvzqdghcclldex08cddc38dau6zty3j5", "600")
    // await stakeFXVault.addValidator("fxvaloper158gmj69jpfsrvee3a220afjs952p4m6kltc67h", "1200")
    // await stakeFXVault.addValidator("fxvaloper1sfw4q2uj8ag79usl562u5wz2rwgzavs0fw4tr2", "200")
    // console.log("Contract address:", stakeFXVault.address);

    // ============ Deploy VestedFX ============

    // const VestedFX = await ethers.getContractFactory("VestedFX");
    // // const vestedFX = await upgrades.upgradeProxy(vest, VestedFX, {kind: "uups", timeout: '0', pollingInterval: '1000'});
    // const vestedFX = await upgrades.deployProxy(VestedFX, [stakeFXVault.address], {kind: "uups", timeout: '0', pollingInterval: '1000'});
    // await vestedFX.deployed();
    
    // console.log("Contract address:", vestedFX.address);


    // ============ Deploy FXFeesTreasury ============

    // const FXFeesTreasury = await ethers.getContractFactory("FeeTreasury");
    // const fxFeesTreasury = await upgrades.deployProxy(FXFeesTreasury, [], {kind: "uups", timeout: '0', pollingInterval: '1000'});
    // await fxFeesTreasury.deployed();

    // await fxFeesTreasury.updateVestedFX(vestedFX.address);
    // await stakeFXVault.updateVestedFX(vestedFX.address);

    // console.log("Contract address:", fxFeesTreasury.address);

    // ============ Deploy RewardDistributor ============

    const RewardDistributor = await ethers.getContractFactory("RewardDistributor");
    const rewardDistributor = await upgrades.upgradeProxy("0x87DD57c7035E4000C22322572987ccE537cb7C25", RewardDistributor, {kind: "uups", timeout: '0', pollingInterval: '1000'});
    // const rewardDistributor = await upgrades.deployProxy(RewardDistributor, [reward, stakeFXVault.address, owner, owner], {kind: "uups", timeout: '0', pollingInterval: '1000'});
    // await rewardDistributor.deployed();

    console.log("Contract address:", rewardDistributor.address);

    // await fxFeesTreasury.updateVestedFX(vestedFX.address);
    // await stakeFXVault.updateVestedFX(vestedFX.address);

    // await stakeFXVault.updateFeeTreasury(fxFeesTreasury.address);
    // await stakeFXVault.updateDistributor(rewardDistributor.address);
    // console.log("Done0");

    // await rewardDistributor.updateLastDistributionTime();
    await rewardDistributor.setTokensPerInterval("1000000000000000")

    console.log("Done1");
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });

    // Contract address: 0x99C24932f7296208A443d10D36540790bF622b74
    // Contract address: 0x7221918Ec074284856C214B4468958b85C57e8A1
    // Contract address: 0x61C53A5411cd81f454C592F2b47A629F35f446F5
    // Contract address: 0x87DD57c7035E4000C22322572987ccE537cb7C25