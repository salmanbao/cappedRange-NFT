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
    // uint256 public constant MAX_SUPPLY = 8192;
    uint256 public constant MINT_FEE = 0.05 ether;
    // uint256 public constant OG_MINT_LIMIT = 128;
    uint256 public ogMinted;
    uint256 public totalMinted;
    bool public salePaused;

    //Merkel tree root for whitelisting addresses
    bytes32 private whiteListMerkleRoot;
    bytes32 private oGMerkleRoot;

     // Base URL string
    string private baseURL;


    mapping(uint256 => bool) public whitelistNumber;

    mapping(address => bool) public ogListed;


      enum PhasesEnum {
        OG,
        WHITELIST,
        PUBLIC
    }


    PhasesEnum currentPhase;

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


    function changePhase(uint8 no) external {
        if(no == 1){
            currentPhase = PhasesEnum.WHITELIST;
        }else if(no == 2){
            currentPhase = PhasesEnum.PUBLIC;
        }else{
            revert("Only 1 or 2 Acceptable");
        }
    }

       /**
     * @dev Returns the token URL of the NFT .
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        // if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
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
        require(currentPhase == PhasesEnum.PUBLIC,"PUBLIC Phase Not Started Yet!");
        require(msg.value >= MINT_FEE, "Insufficient funds to mint");
         for (uint256 i = 0; i < _noOfMint; i++) {
            // TODO ask when we have less butn _noOfMint is more than the limit, what to do?
            // 1- mint available
            // 2- revert
            require(totalMinted < 8192, "Maximum supply reached");
            totalMinted++;
            _safeMint(msg.sender, totalMinted);
        }
    }



        // Allow WhiteListed to mint NFTs 
    function whiteListedMint(bytes32[] calldata _merkleProof) external payable saleNotPaused {
        require(currentPhase == PhasesEnum.WHITELIST,"Whitelist Phase Not Started Yet!");
        require(msg.value >= MINT_FEE, "Insufficient funds to mint");
        require(MerkleProof.verify(
                        _merkleProof,
                        whiteListMerkleRoot,
                        keccak256(abi.encodePacked(msg.sender))
                    ),
                    "User Not Whitelisted"
                );
        //TODO check total
        totalMinted++;
        _safeMint(msg.sender, totalMinted);
    }

    function ogMint() external saleNotPaused  returns(bool x) {
        // bytes32[] calldata _merkleProof
        // require(MerkleProof.verify(
        //                 _merkleProof,
        //                 oGMerkleRoot,
        //                 keccak256(abi.encodePacked(msg.sender))
        //             ),
        //             "User Not OG Player"
        //         );
        // require(ogListed[msg.sender] == false, "Already Minted NFT");
        require(totalMinted < 128, "OG Mint limit not reached");
        // uint256 randomNumber = createRandomNumber();
        // uint256 randomNumber = 10;
        while(true){

        uint256 randomNumber = createRandomNumber();

                console.log("randomNumber Generate",randomNumber);

        
            if(whitelistNumber[randomNumber] == false){
                // randomNumber = createRandomNumber();
                // console.log("randomNumber 1",randomNumber);
                // return randomNumber;


                whitelistNumber[randomNumber] = true;
                totalMinted++;
                // ogListed[msg.sender] = true;
                console.log("randomNumber 2",randomNumber);
                _safeMint(msg.sender, randomNumber);
                console.log("randomNumber 3",randomNumber);
                break;
            }

            
            // else{
            //     whitelistNumber[randomNumber] = true;
            //     totalMinted++;
            //     console.log("randomNumber 2",randomNumber);
            //     _safeMint(msg.sender, randomNumber);
            //     console.log("randomNumber 3",randomNumber);
            //     break;
            // }
            continue;
        }
            return true;


    }

        // Allow owner to mint NFTs even if sale is paused
    function ownerMint(address _to) external onlyOwner {
        require(totalMinted < 8192, "Maximum supply reached");
        totalMinted++;
        _safeMint(_to, totalMinted);
    }

    // Withdraw ether balance to owner
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }

     function createRandomNumber() public view returns (uint256)
{
    return block.prevrandao % 128;
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
