import { Contract, Signer } from "ethers";
import { ethers, upgrades } from "hardhat";
import "@nomiclabs/hardhat-ethers";

async function main() {
    const signers: Signer[] = await ethers.getSigners()
    const DogEatDogWorldNFT = await ethers.getContractFactory("DogEatDogWorldNFT", signers[1]);
    const dogEatDogWorldNFT = await upgrades.upgradeProxy("0xABE8AEa692118dd2b9a48F5122B9687363a3cA64", DogEatDogWorldNFT);
    await dogEatDogWorldNFT.deployed();
    console.log("Box deployed to:", dogEatDogWorldNFT.address);


}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.log(error);
        process.exit(1);
    })