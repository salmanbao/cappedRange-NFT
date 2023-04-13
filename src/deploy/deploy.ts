import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'


const deployContract: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment,
) {

  const signers = await hre.ethers.getSigners();
  
    const DogEatDogWorldNFT = await hre.ethers.getContractFactory("DogEatDogWorldNFT", signers[1]);
    const dogEatDogWorldNFT = await DogEatDogWorldNFT.deploy();

    console.log("dogEatDogWorldNFT Address", dogEatDogWorldNFT.address);
}

export default deployContract