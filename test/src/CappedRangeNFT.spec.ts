import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract, BigNumber, Signer } from "ethers";
import { keccak256, parseEther } from "ethers/lib/utils";
import hre, { ethers, upgrades } from "hardhat";
import MerkleTree from "merkletreejs/dist/MerkleTree";


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
    cappedRangeNFT = await upgrades.deployProxy(CappedRangeNFT);
    await cappedRangeNFT.deployed();

  });


  // Test Case Run using Decrease Limit 
  // uint256 public constant MAX_SUPPLY = 105;
  // uint256 public constant OG_MINT_LIMIT = 4;
  // Rnadom Numbr generator generate number in  % 4


  it("MerkleTree Creationn And Set Markle Tree Root", async function () {

    whiteListedAddresses = [owner, user1, user3, user5, user4];

    const leafNodes = whiteListedAddresses.map((x: SignerWithAddress) => keccak256(x.address));
    mtree = new MerkleTree(leafNodes, keccak256, { sort: true });
    root = mtree.getHexRoot()

    await cappedRangeNFT.connect(owner).setOGMerkelRoot(root)
  })

  it("Sale is currently paused", async function () {

    for (let i = 0; i < whiteListedAddresses.length - 1; i++) {
      const leaf = keccak256(whiteListedAddresses[i].address)
      const proof = mtree.getHexProof(leaf)
      await expect(cappedRangeNFT.connect(whiteListedAddresses[i]).ogMint(proof)).to.be.revertedWith("Sale is currently paused");
    }

  })

  it("Sale is  unpaused", async function () {

    await cappedRangeNFT.connect(owner).unpauseSale();

  })


  it("Mint NFT", async function () {


    for (let i = 0; i < whiteListedAddresses.length - 1; i++) {
      const leaf = keccak256(whiteListedAddresses[i].address)
      const proof = mtree.getHexProof(leaf)
      await cappedRangeNFT.connect(whiteListedAddresses[i]).ogMint(proof);
    }

  })

  it("USER_NOT_OG_PLAYER", async function () {

    const leaf = keccak256(user2.address)
    const proof = mtree.getHexProof(leaf)
    await expect(cappedRangeNFT.connect(user2).ogMint(proof)).to.be.revertedWith("USER_NOT_OG_PLAYER()");

  })

  it("OG_MINT_LIMIT_REACHED", async function () {

    const leaf = keccak256(user4.address)
    const proof = mtree.getHexProof(leaf)
    await expect(cappedRangeNFT.connect(user4).ogMint(proof)).to.be.revertedWith("OG_MINT_LIMIT_REACHED()");

  })

  it("ALREADY_MINTED_NFT", async function () {

    const leaf = keccak256(user1.address)
    const proof = mtree.getHexProof(leaf)
    await expect(cappedRangeNFT.connect(user1).ogMint(proof)).to.be.revertedWith("ALREADY_MINTED_NFT()");

  })

  it("Sale Pause", async function () {

    await cappedRangeNFT.connect(owner).pauseSale();

  })

  it(" Owner Mint When Pause ", async function () {

    await cappedRangeNFT.connect(owner).ownerMint(user1.address)
    await cappedRangeNFT.connect(owner).ownerMint(user1.address)
    await cappedRangeNFT.connect(owner).ownerMint(user1.address)
    await cappedRangeNFT.connect(owner).ownerMint(user1.address)
    await cappedRangeNFT.connect(owner).ownerMint(user1.address)

  })


  it("MerkleTree Creationn And Set Markle Tree Root For White List User", async function () {


    whiteListedAddresses = [owner, user2, user4, user6];

    const leafNodes = whiteListedAddresses.map((x: SignerWithAddress) => keccak256(x.address));
    mtree = new MerkleTree(leafNodes, keccak256, { sort: true });
    root = mtree.getHexRoot()

    await cappedRangeNFT.connect(owner).setWhiteListMerkelRoot(root)

  })

  it("Sale is  unpaused", async function () {

    await cappedRangeNFT.connect(owner).unpauseSale();

  })

it("PHASE_NOT_STARTED_YET",async function () {
  
  for (let i = 0; i < whiteListedAddresses.length; i++) {
    const leaf = keccak256(whiteListedAddresses[i].address)
    const proof = mtree.getHexProof(leaf)
    await expect(cappedRangeNFT.connect(whiteListedAddresses[i]).whiteListedMint(proof, 5, { value: parseEther("0.05") })).to.be.revertedWith("PHASE_NOT_STARTED_YET()");
  }

})

it("Next Phase not started Yet", async function () {

  await expect(cappedRangeNFT.publicMint(5, { value: parseEther("0.05") })).to.be.revertedWith("PHASE_NOT_STARTED_YET()");

})


  it("USER_NOT_WHITELISTED", async function () {

    const leaf = keccak256(user1.address)
    const proof = mtree.getHexProof(leaf)
    await expect(cappedRangeNFT.connect(user1).whiteListedMint(proof, 5, { value: parseEther("0.05") })).to.be.revertedWith("USER_NOT_WHITELISTED()");

  })

  it("Next Phase not started Yet", async function () {

    await expect(cappedRangeNFT.publicMint(5, { value: parseEther("0.05") })).to.be.revertedWith("PHASE_NOT_STARTED_YET()");

  })



  it("Next Phase White List Phase", async function () {

    await cappedRangeNFT.connect(owner).changePhase(1)

  })

  it("Mint NFT OVER range", async function () {

    for (let i = 0; i < whiteListedAddresses.length; i++) {
      const leaf = keccak256(whiteListedAddresses[i].address)
      const proof = mtree.getHexProof(leaf)
      await expect(cappedRangeNFT.connect(whiteListedAddresses[i]).whiteListedMint(proof, 11, { value: parseEther("0.05") })).to.be.revertedWith("MAX_MINT_LIMIT_INCREASE()");
    }

  })

  it("Mint NFT in White List Phase", async function () {

    for (let i = 0; i < whiteListedAddresses.length; i++) {
      const leaf = keccak256(whiteListedAddresses[i].address)
      const proof = mtree.getHexProof(leaf)
      await cappedRangeNFT.connect(whiteListedAddresses[i]).whiteListedMint(proof, 5, { value: parseEther("0.05") });
    }

  })


  it("Next Phase not started Yet", async function () {

    await expect(cappedRangeNFT.publicMint(5, { value: parseEther("0.05") })).to.be.revertedWith("PHASE_NOT_STARTED_YET()");

  })


  it(" Next Phase Started Public Phase ", async function () {

    await cappedRangeNFT.connect(owner).changePhase(2)

  })

  it("Mint NFT", async function () {

    for (let i = 0; i < 15; i++) {
      await cappedRangeNFT.publicMint(5, { value: parseEther("0.05") });
    }

  })

  it("INSUFFICIENT_FUNDS", async function () {

    await expect(cappedRangeNFT.publicMint(1, { value: parseEther("0.03") })).to.be.revertedWith("INSUFFICIENT_FUNDS()");


  })
  it("MAX_MINT_LIMIT_INCREASE", async function () {

    await expect(cappedRangeNFT.publicMint(11, { value: parseEther("0.05") })).to.be.revertedWith("MAX_MINT_LIMIT_INCREASE()");

  })

  it("Sale Pause", async function () {

    await cappedRangeNFT.connect(owner).pauseSale();

  })

  it("Sale is currently paused", async function () {

    await expect(cappedRangeNFT.publicMint(1, { value: parseEther("0.05") })).to.be.revertedWith("Sale is currently paused");

  })

  it("Un Pause Sale", async function () {

    await cappedRangeNFT.connect(owner).unpauseSale();

  })

  it("MINT NFT", async function () {

    await cappedRangeNFT.publicMint(1, { value: parseEther("0.05") });

  })

  it("MAX_SUPPLY_REACHED", async function () {

    await expect(cappedRangeNFT.publicMint(1, { value: parseEther("0.05") })).to.be.revertedWith("MAX_SUPPLY_REACHED()");

  })


});
