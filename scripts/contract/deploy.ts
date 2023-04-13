import { Contract, Signer } from "ethers";
import { ethers, upgrades } from "hardhat";
import "@nomiclabs/hardhat-ethers";

async function main() {
    const signers: Signer[] = await ethers.getSigners()
    const DogEatDogWorldNFT = await ethers.getContractFactory("DogEatDogWorldNFT", signers[1]);
    const dogEatDogWorldNFT = await upgrades.deployProxy(DogEatDogWorldNFT);
    await dogEatDogWorldNFT.deployed();
    console.log("Box deployed to:", dogEatDogWorldNFT.address);
    // await dogEatDogWorldNFT.initialize();
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.log(error);
        process.exit(1);
    })