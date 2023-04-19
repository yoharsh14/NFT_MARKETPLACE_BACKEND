const { network } = require("hardhat");
const { developmentChains } = require("../helper-hardhat.config");
const { verify } = require("../utils/verify");

module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();
    
    //deploying reentrance
    log("------------------------------------------");
    const reentrance = await deploy("ReentrantVulnerable", {
        from: deployer,
        args: [],
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    });
    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        await verify(reentrance.address, args);
    }
    log("-------------------------------------------");
   
    // deploying attack
    const attack = await deploy("Attack", {
        from: deployer,
        args: [reentrance.address],
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    });

    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        await verify(attack.address, args);
    }

    // Two vulnerabilities that causes attacks
    //reentrancy
    // oracle attacks
};
module.exports.tags = ["reentrance"];
