const { ethers, getNamedAccounts, deployments, network } = require("hardhat");
const { developmentChains } = require("../helper-hardhat.config");
const { assert, expect } = require("chai");
!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Nft MarketPlace testing", () => {
          let nftMarketplace,
              nftMarketplaceContract,
              basicNft,
              basicNftContract,
              Nftaddress,
              player,
              deployer;
          const PRICE = ethers.utils.parseEther("0.1");
          const TOKEN_ID = 0;

          beforeEach(async () => {
              accounts = await ethers.getSigners(); // could also do with getNamedAccounts
              deployer = accounts[0];
              player = accounts[1];
              await deployments.fixture(["main"]);
              nftMarketplaceContract = await ethers.getContract("NftMarketplace");
              nftMarketplace = nftMarketplaceContract.connect(deployer);
              basicNftContract = await ethers.getContract("BasicNFT");
              basicNft = await basicNftContract.connect(deployer);
              await basicNft.mintNft();
              await basicNft.approve(nftMarketplaceContract.address, TOKEN_ID);
              Nftaddress = basicNft.address;
          });
          describe("first", async () => {
              it("Listing Items", async () => {
                  //   await expect(await nftMarketplace.listItem(Nftaddress, TOKEN_ID, PRICE))
                  //       .to.emit(nftMarketplace, "ItemListed")
                  //       .withArgs(deployer, Nftaddress, TOKEN_ID, PRICE);
                  await nftMarketplace.listItem(Nftaddress, TOKEN_ID, PRICE);
                  const playerConnectedNftMarketplace = nftMarketplace.connect(player);
                //   await playerConnectedNftMarketplace.buyItem(Nftaddress, TOKEN_ID, {
                //       value: PRICE,
                //   });
                  const newOwner = await basicNft.ownerOf(TOKEN_ID);
                  const deployerProceeds = await nftMarketplace.getProceeds(deployer);
                  assert(newOwner.toString() == player);
                  assert(deployerProceeds.toString() == PRICE.toString());
              });
          });
      });
