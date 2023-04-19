// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
error NftMarketplace_PriceMustBeAboveZero();
error NftMarketplace_NotApprovedForMarketplace();
error NftMarketplace_NotOwner();
error NftMarketplace_AlreadyListed(address nftAddress, uint256 tokenId);

contract NftMarketplace {
    struct Listing {
        uint256 price;
        address seller;
    }
    event ItemList(address indexed seller, address nftAddress, uint256 tokenId, uint256 price);
    //NFT contract address -> NFT TokenId -> Listing
    mapping(address => mapping(uint256 => Listing)) private s_listings;

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
        emit ItemList(msg.sender, nftAddress, tokenId, price);
    }

 
}

// 1. `listItem`: List NFTs on the marketplace
// 2. `buyItem`: Buy the NFTs
// 3. `cancelItem`: Cancel a listing
// 4. `updateListing`: Update Price
// 5. `withdrawProceeds`: Withdraw payment for my bought NFT
