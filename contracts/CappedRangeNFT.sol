pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "hardhat/console.sol";

contract CappedRangeNFT is ERC721 {
    using SafeMath for uint256;

    // State variables
    address public owner;
    uint256 public constant MAX_SUPPLY = 105;
    uint256 public constant MINT_FEE = 0.05 ether;
    uint256 public constant OG_MINT_LIMIT = 4;
    uint256 public constant MAX_MINT_LIMIT = 10;
    uint256 public totalMinted;
    bool public salePaused;

    //Merkel tree root for whitelisting addresses
    bytes32 private whiteListMerkleRoot;
    bytes32 private oGMerkleRoot;

    // Base URL string
    string private baseURL;

    uint256 private nonce = 0;

    mapping(uint256 => bool) public whitelistNumber;

    mapping(address => bool) public ogListed;

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

    // Constructor
    constructor() ERC721("Capped Range", "CR") {
        owner = msg.sender;
        currentPhase = PhasesEnum.OG;
        salePaused = true; // Sale paused at deployment
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
            revert("Only 1 or 2 Acceptable");
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
                ? string(abi.encodePacked(baseURL, tokenId))
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
        if(_noOfMint > MAX_MINT_LIMIT) revert MAX_MINT_LIMIT_INCREASE();
        if (totalMinted.add(_noOfMint) > MAX_SUPPLY)
            revert MAX_SUPPLY_REACHED();
        if (currentPhase != PhasesEnum.PUBLIC) revert PHASE_NOT_STARTED_YET();
        if (msg.value < MINT_FEE) revert INSUFFICIENT_FUNDS();
        for (uint256 i = 0; i < _noOfMint; i++) {
            totalMinted++;
            _safeMint(msg.sender, totalMinted);
        }
    }

    // Allow WhiteListed to mint NFTs
    function whiteListedMint(
        bytes32[] calldata _merkleProof,
        uint256 _noOfMint
    ) external payable saleNotPaused {
        if (
            MerkleProof.verify(
                _merkleProof,
                whiteListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ) == false
        ) revert USER_NOT_WHITELISTED();
        if (totalMinted.add(_noOfMint) > MAX_SUPPLY)
            revert MAX_SUPPLY_REACHED();
        if (currentPhase != PhasesEnum.WHITELIST)
            revert PHASE_NOT_STARTED_YET();
        if (msg.value < MINT_FEE) revert INSUFFICIENT_FUNDS();
        for (uint256 i = 0; i < _noOfMint; i++) {
            totalMinted++;
            _safeMint(msg.sender, totalMinted);
        }
    }

    function ogMint(bytes32[] calldata _merkleProof) external saleNotPaused {
        if (
            MerkleProof.verify(
                _merkleProof,
                oGMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ) == false
        ) revert USER_NOT_OG_PLAYER();
        if (ogListed[msg.sender] == true) revert ALREADY_MINTED_NFT();
        if (totalMinted >= OG_MINT_LIMIT) revert OG_MINT_LIMIT_REACHED();
        uint256 randomNumber = generateRandomNumber();
        totalMinted++;
        ogListed[msg.sender] = true;
        _safeMint(msg.sender, randomNumber);
    }

    // Allow owner to mint NFTs even if sale is paused
    function ownerMint(address _to) external onlyOwner {
        if (totalMinted > MAX_SUPPLY) revert MAX_SUPPLY_REACHED();
        totalMinted++;
        _safeMint(_to, totalMinted);
    }

    // Withdraw ether balance to owner
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }

    function generateRandomNumber() public returns (uint256) {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    msg.sender,
                    nonce
                )
            )
        ) % 4;

        // 128
        nonce++;
        while (whitelistNumber[randomNumber] == true) {
            randomNumber =
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
                4;
                // 128
            nonce++;
        }
        whitelistNumber[randomNumber] = true;
        return randomNumber;
    }

    // Pause and Unpause sale
    function pauseSale() external onlyOwner {
        require(!salePaused, "Sale is already paused");
        salePaused = true;
    }

    function unpauseSale() external onlyOwner {
        require(salePaused, "Sale is already unpaused");
        salePaused = false;
    }
}
