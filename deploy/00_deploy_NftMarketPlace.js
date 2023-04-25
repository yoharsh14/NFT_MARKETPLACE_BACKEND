const { network } = require("hardhat");
const { developmentChains } = require("../helper-hardhat.config");
const { verify } = require("../utils/verify");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deployer } = await getNamedAccounts();
    const { deploy, log } = deployments;
    const chainId = network.chainId;
    const nftMarketplace = await deploy("NftMarketplace", {
        from: deployer,
        log: true,
        args: [],
        waitConfirmations: network.config.blockConfirmations || 1,
    });
    if (!developmentChains.includes(network.name)) {
        log("Verifying...");
        verify(nftMarketplace.address, []);
    }
    log("---------------Deployed NFT MARKET PlACE CONTRACT!!----------------")
};
module.exports.tags = ["nft","main"]