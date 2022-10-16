const hre = require("hardhat");

async function main() {
  const p2pNFTFactory = await hre.ethers.getContractFactory("P2PNFTFactory");
  const lock = await p2pNFTFactory.deploy({ value: 0 });

  await lock.deployed();
  console.log(
    `deployed to ${lock.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});