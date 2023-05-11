// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract CappedRangeNFT is Initializable, ERC721Upgradeable {
    using SafeMathUpgradeable for uint256;
    using StringsUpgradeable for uint256;
    // State variables
    address public owner;
    uint256 public constant MAX_SUPPLY = 8192;
    uint256 public constant MINT_FEE = 0.05 ether;
    uint256 public constant OG_MINT_LIMIT = 128;
    uint256 public constant MAX_MINT_LIMIT = 10;
    // Counter to count total minted NFTs
    uint256 public totalMinted;
    // Counter for NFT IDs
    uint256 public mintIdCounter;
    // Counter for OG mint
    uint256 public oGMintCounter;

    bool public salePaused;

    //Merkel tree root for whitelisting addresses
    bytes32 private whiteListMerkleRoot;
    //Merkel tree root for OG Players addresses
    bytes32 private oGMerkleRoot;

    // Base URL string
    string private baseURL;

    mapping(uint256 => bool) public mintedIDs;

    mapping(address => bool) public oGPlayersMinted;

    enum PhasesEnum {
        OG,
        WHITELIST,
        PUBLIC
    }

    PhasesEnum currentPhase;

    // Check supply
    error MAX_SUPPLY_REACHED();
    error ALREADY_MINTED_NFT();
    error OG_MINT_LIMIT_REACHED();
    error INSUFFICIENT_FUNDS();
    error PHASE_NOT_STARTED_YET();
    error USER_NOT_WHITELISTED();
    error USER_NOT_OG_PLAYER();
    error MAX_MINT_LIMIT_INCREASE();
    error ALREADY_PAUSED();
    error ALREADY_UNPAUSED();
    error ONLY_1_OR_2_ACCEPTABLE();

    function initialize() public initializer {
        __ERC721_init("Capped Range", "CR");
        owner = msg.sender;
        currentPhase = PhasesEnum.OG;
        salePaused = true; // Sale paused at deployment
        totalMinted = 0;
        mintIdCounter = 0;
    }

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier saleNotPaused() {
        require(!salePaused, "Sale is currently paused");
        _;
    }

    function changePhase(uint8 no) external onlyOwner {
        if (no == 1) {
            currentPhase = PhasesEnum.WHITELIST;
        } else if (no == 2) {
            currentPhase = PhasesEnum.PUBLIC;
        } else {
            revert ONLY_1_OR_2_ACCEPTABLE();
        }
    }

    /**
     * @dev Returns the token URL of the NFT .
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        return
            bytes(baseURL).length > 0
                ? string(abi.encodePacked(baseURL, tokenId.toString(), ".json"))
                : "";
    }

    /**
     * @dev Set the base URL of the NFT .
     * Can only be called by owner.
     */
    function setbaseURI(string memory _uri) external onlyOwner {
        baseURL = _uri;
    }

    /**
     * @dev Sets the new Owner of the smart contract.
     * Can only be called by owner.
     */
    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    /**
     * @dev Sets merkelRoot varriable.
     * Only owner can call it.
     */
    function setWhiteListMerkelRoot(bytes32 _merkleRoot) external onlyOwner {
        whiteListMerkleRoot = _merkleRoot;
    }

    function getWhiteListMerkelRoot() external view returns (bytes32) {
        return whiteListMerkleRoot;
    }

    /**
     * @dev Sets merkelRoot varriable.
     * Only owner can call it.
     */
    function setOGMerkelRoot(bytes32 _merkleRoot) external onlyOwner {
        oGMerkleRoot = _merkleRoot;
    }

    function getOGMerkelRoot() external view returns (bytes32) {
        return oGMerkleRoot;
    }

    // Mint function
    function publicMint(uint256 _noOfMint) external payable saleNotPaused {
        if (_noOfMint > MAX_MINT_LIMIT) revert MAX_MINT_LIMIT_INCREASE();
        if (totalMinted.add(_noOfMint) > MAX_SUPPLY)
            revert MAX_SUPPLY_REACHED();
        if (currentPhase != PhasesEnum.PUBLIC) revert PHASE_NOT_STARTED_YET();
        if (msg.value < MINT_FEE.mul(_noOfMint)) revert INSUFFICIENT_FUNDS();
        for (uint256 i = 0; i < _noOfMint; i++) {
            // Counter to count total minted NFTs
            totalMinted++;
            // Counter for NFT IDs
            mintIdCounter++;

            while (mintedIDs[mintIdCounter] = true) {
                mintIdCounter++;
            }

            mintedIDs[mintIdCounter] = true;
            _safeMint(msg.sender, mintIdCounter);
        }
    }

    // Allow WhiteListed to mint NFTs
    function whiteListedMint(
        bytes32[] calldata _merkleProof,
        uint256 _noOfMint
    ) external payable saleNotPaused {
        if (_noOfMint > MAX_MINT_LIMIT) revert MAX_MINT_LIMIT_INCREASE();
        if (
            MerkleProofUpgradeable.verify(
                _merkleProof,
                whiteListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ) == false
        ) revert USER_NOT_WHITELISTED();
        if (totalMinted.add(_noOfMint) > MAX_SUPPLY)
            revert MAX_SUPPLY_REACHED();
        if (currentPhase != PhasesEnum.WHITELIST)
            revert PHASE_NOT_STARTED_YET();

        if (msg.value < MINT_FEE.mul(_noOfMint)) revert INSUFFICIENT_FUNDS();
        for (uint256 i = 0; i < _noOfMint; i++) {
            // Counter to count total minted NFTs
            totalMinted++;
            // Counter for NFT IDs
            mintIdCounter++;
            while (mintedIDs[mintIdCounter] = true) {
                mintIdCounter++;
            }
            mintedIDs[mintIdCounter] = true;
            _safeMint(msg.sender, mintIdCounter);
        }
    }

    function oGMint(bytes32[] calldata _merkleProof) external saleNotPaused {
        if (
            MerkleProofUpgradeable.verify(
                _merkleProof,
                oGMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ) == false
        ) revert USER_NOT_OG_PLAYER();

        if (oGPlayersMinted[msg.sender] == true) revert ALREADY_MINTED_NFT();
        if (oGMintCounter >= OG_MINT_LIMIT) revert OG_MINT_LIMIT_REACHED();
        if (totalMinted >= MAX_MINT_LIMIT) revert MAX_SUPPLY_REACHED();
        uint256 randomId = randomIdGenerator();
        totalMinted++;
        oGMintCounter++;
        oGPlayersMinted[msg.sender] = true;
        mintedIDs[randomId] = true;
        _safeMint(msg.sender, randomId);
    }

    // Allow owner to mint NFTs even if sale is paused
    function ownerMint(address _to) external onlyOwner {
        if (totalMinted >= MAX_SUPPLY) revert MAX_SUPPLY_REACHED();
        // Counter to count total minted NFTs
        totalMinted++;
        // Counter for NFT IDs
        mintIdCounter++;

        while (mintedIDs[mintIdCounter] = true) {
            mintIdCounter++;
        }
        mintedIDs[mintIdCounter] = true;
        _safeMint(_to, mintIdCounter);
    }

    // Withdraw ether balance to owner
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }

    function randomIdGenerator() public view returns (uint256) {
        uint256 nonce = 0;
        uint256 randomID = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    msg.sender,
                    nonce
                )
            )
        ) % MAX_SUPPLY;

        // 128
        nonce++;
        while (mintedIDs[randomID] == true) {
            randomID =
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.prevrandao,
                            msg.sender,
                            nonce
                        )
                    )
                ) %
                MAX_SUPPLY;
            nonce++;
        }

        return randomID;
    }

    // Pause and Unpause sale
    function pauseSale() external onlyOwner {
        // require(!salePaused, "Sale is already paused");
        if (salePaused) revert ALREADY_PAUSED();
        salePaused = true;
    }

    function unpauseSale() external onlyOwner {
        // require(salePaused, "Sale is already unpaused");
        if (!salePaused) revert ALREADY_UNPAUSED();
        salePaused = false;
    }
}
