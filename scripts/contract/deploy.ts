import { Contract, Signer } from "ethers";
import { ethers, upgrades } from "hardhat";
import "@nomiclabs/hardhat-ethers";
import { log } from "console";

async function main() {
    const signers: Signer[] = await ethers.getSigners()
    

    const CappedRangeNFT = await ethers.getContractFactory("CappedRangeNFT", signers[1]);
    const cappedRangeNFT = await upgrades.deployProxy(CappedRangeNFT);
    await cappedRangeNFT.deployed();

    console.log("Deployed Address",cappedRangeNFT.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.log(error);
        process.exit(1);
    })