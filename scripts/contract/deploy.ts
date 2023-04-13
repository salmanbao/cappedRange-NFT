import { Contract, Signer } from "ethers";
import { ethers, upgrades } from "hardhat";
import "@nomiclabs/hardhat-ethers";

async function main() {
    const signers: Signer[] = await ethers.getSigners()
    
    const CappedRangeNFT = await ethers.getContractFactory("CappedRangeNFT", signers[1]);

    const cappedRangeNFT = await CappedRangeNFT.deploy();
    console.log("cappedRangeNFT deployed to:", cappedRangeNFT.address);
    // await dogEatDogWorldNFT.initialize();
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.log(error);
        process.exit(1);
    })