import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract, BigNumber, Signer } from "ethers";
import { keccak256, parseEther } from "ethers/lib/utils";
import hre, { ethers, upgrades } from "hardhat";
import MerkleTree from "merkletreejs/dist/MerkleTree";
import { increaseTime } from "../utils/utilities";
import { log } from "console";



const bufToHex = (x: any) => '0x' + x.toString('hex')

describe("CappedRangeNFT Token", function () {

  let signers: Signer[];

  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  let user3: SignerWithAddress;

  let user4: SignerWithAddress;
  let user5: SignerWithAddress;
  let user6: SignerWithAddress;


  let cappedRangeNFT: Contract;
  let mtree: MerkleTree;
  let root: string;

  let whiteListedAddresses: SignerWithAddress[];

  before(async () => {
    [owner, user1, user2, user3, user4, user5, user6] = await ethers.getSigners();


    const CappedRangeNFT = await ethers.getContractFactory("CappedRangeNFT", owner);

    cappedRangeNFT = await CappedRangeNFT.deploy();
  });

  it("Base URL", async function(){

    log(cappedRangeNFT.functions)

    await cappedRangeNFT.connect(owner).unpauseSale();

    await cappedRangeNFT.ogMint();

    await cappedRangeNFT.ogMint();

    await cappedRangeNFT.ogMint();

    await cappedRangeNFT.ogMint();

    await cappedRangeNFT.ogMint();

    // await cappedRangeNFT.ogMint();

    // await cappedRangeNFT.ogMint();
    // await cappedRangeNFT.ogMint();

    // await cappedRangeNFT.ogMint();

    // await cappedRangeNFT.ogMint();

    // await cappedRangeNFT.ogMint();


  })



});
