// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; 
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
error NftMarketplace_PriceMustBeAboveZero();
error NftMarketplace_NotApprovedForMarketplace();
error NftMarketplace_NotOwner();
error NftMarketplace_NotListed(address nftAddress, uint256 tokenId);
error NftMarketplace_AlreadyListed(address nftAddress, uint256 tokenId);
error NftMarketplace_PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
error NftMarketplace_NoProceeds();
error NftMarketplace_TransferFailed();

contract NftMarketplace is ReentrancyGuard {
    struct Listing {
        uint256 price;
        address seller;
    }
    // Events
    event ItemListed(address indexed seller, address nftAddress, uint256 tokenId, uint256 price);
    event ItemBought(address indexed buyer, address nftAddress, uint256 tokenId, uint256 price);
    event ItemCanceled(address indexed seller, address nftAddress, uint256 tokenId);

    //NFT contract address -> NFT TokenId -> Listing
    mapping(address => mapping(uint256 => Listing)) private s_listings;

    //Seller address -> Amount earned
    mapping(address => uint256) private s_proceeds;

    ////////////////////
    //    Modifiers   //
    ////////////////////
    modifier notListed(
        address nftAddress,
        uint256 tokenId,
        address owner
    ) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price > 0) {
            revert NftMarketplace_AlreadyListed(nftAddress, tokenId);
        }
        _;
    }

    modifier isOwner(
        address nftAddress,
        uint256 tokenId,
        address spender
    ) {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        if (spender != owner) {
            revert NftMarketplace_NotOwner();
        }
        _;
    }

    modifier isListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price <= 0) {
            revert NftMarketplace_NotListed(nftAddress, tokenId);
        }
        _;
    }

    ///////////////////
    // Main Function //
    ///////////////////

    /** @notice Method for lisitng your NFT on the marketplace
     * @param nftAddress: Address of the NFT
     * @param tokenId: The Token ID of the NFT
     * @param price: sale price of the listed NFT
     * @dev Technically, we could have the contract be the escrow for the NFTs
     * but this way people can still hold their NFTs when listed.
     */
    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) external notListed(nftAddress, tokenId, msg.sender) isOwner(nftAddress, tokenId, msg.sender) {
        if (price <= 0) {
            revert NftMarketplace_PriceMustBeAboveZero();
        }
        // 1. setn the NFT to the contract. Transfer -> Contract "hold" the NFT.
        //--> using this) 2. Owners can still hold their NFT, and give the marketplace approval to set the NFT for them.
        IERC721 nft = IERC721(nftAddress);
        if (nft.getApproved(tokenId) != address(this)) {
            revert NftMarketplace_NotApprovedForMarketplace();
        }
        s_listings[nftAddress][tokenId] = Listing(price, msg.sender);
        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }

    // I can also use crypto token for buying the NFT's,
    // by checking the price with the help of chainlink priceFeed

    function buyItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) external payable nonReentrant isListed(nftAddress, tokenId) {
        Listing memory listedItem = s_listings[nftAddress][tokenId];
        if (msg.value < listedItem.price) {
            revert NftMarketplace_PriceNotMet(nftAddress, tokenId, price);
        }
        // We don't just send seller the money ...
        // https://fravoll.github.io/solidity-patterns/pull_over_push.html

        //sending the money to the user
        // Have them withdraw the money
        s_proceeds[listedItem.seller] = s_proceeds[listedItem.seller] + msg.value;
        delete (s_listings[nftAddress][tokenId]);
        IERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);
        //check to ensure
        emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price);
    }

    function cancleListing(
        address nftAddress,
        uint256 tokenId
    ) external isOwner(nftAddress, tokenId, msg.sender) isListed(nftAddress, tokenId) {
        delete (s_listings[nftAddress][tokenId]);
        emit ItemCanceled(msg.sender, nftAddress, tokenId);
    }

    function updateListing(
        address nftAddress,
        uint256 tokenId,
        uint256 newPrice
    ) external isListed(nftAddress, tokenId) isOwner(nftAddress, tokenId, msg.sender) {
        s_listings[nftAddress][tokenId].price = newPrice;
        emit ItemListed(msg.sender, nftAddress, tokenId, newPrice);
    }

    function withdrawProceeds() external {
        uint256 proceeds = s_proceeds[msg.sender];
        if (proceeds <= 0) revert NftMarketplace_NoProceeds();
        s_proceeds[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: proceeds}("");
        if (!success) {
            revert NftMarketplace_TransferFailed();
        }
    }

    ///////////////////////
    // getter Functions ///
    ///////////////////////
    function getlisting(
        address nftAddress,
        uint256 tokenId
    ) external view returns (Listing memory) {
        return s_listings[nftAddress][tokenId];
    }

    function getProceeds(address seller) external view returns (uint256) {
        return s_proceeds[seller];
    }
}

// 1. `listItem`: List NFTs on the marketplace
// 2. `buyItem`: Buy the NFTs
// 3. `cancelItem`: Cancel a listing
// 4. `updateListing`: Update Price
// 5. `withdrawProceeds`: Withdraw payment for my bought NFT
