const { network, getNamedAccounts, deployments, ethers } = require("hardhat");
const { developmentChains } = require("../../helper-hardhat.config");
const { assert } = require("chai");
const DEPOSIT_AMOUNT = ethers.parseEther("10");

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Rentrance Normal Function Test and Attack", async () => {
          let reentrance, deployer, attack;

          beforeEach(async () => {
              deployer = (await getNamedAccounts()).deployer;
              await deployments.fixture("reentrance");
              reentrance = await ethers.getContract("ReentrantVulnerable");
              attack = await ethers.getContract("Attack");
          });

          describe("Functions", async () => {
              it("depositing 10 and checking the balance of the contract after depositing", async () => {
                  await reentrance.deposit(DEPOSIT_AMOUNT);
                  const balance = await reentrance.balance();
                  assert.equal(balance, DEPOSIT_AMOUNT);
              });
              it("withdrawing", async () => {
                  await reentrance.deposit(DEPOSIT_AMOUNT);
                  const balanceBeforeWithdrawl = await reentrance.getBalance();
                  await reentrance.withdraw();
                  const balanceAfterWithdrawl = await reentrance.getBalance();
                  assert.equal(balanceBeforeWithdrawl - balanceAfterWithdrawl, DEPOSIT_AMOUNT);
              });
          });
      });
