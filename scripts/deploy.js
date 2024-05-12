// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

const tokens = (n) => {
  return ethers.utils.parseUnits(n.toString(), 'ether')
}

async function main() {
  [buyer, seller, inspector, lender] = await ethers.getSigners();

  const RealEstate = await ethers.getContractFactory('RealEstate');
  const realEstate = await RealEstate.deploy();
  await realEstate.deployed();

  console.log(`Deployed Real Estate Contract at: ${realEstate.address}`)
  console.log(`Minting 3 properties...\n`)

  let mint_transaction = await realEstate.connect(seller).mint(`http://127.0.0.1:8080/ipfs/QmQvziYR7NnQD3MvbPRTJ3aVA35KFbXnZqLAAfBLCffGiV?filename=1.json`);
  await mint_transaction.wait();
  mint_transaction = await realEstate.connect(seller).mint(`http://127.0.0.1:8080/ipfs/QmUih4CTef8nk86UVKuaRjFcLYKqLfKxBN9omQgStHB85s?filename=2.json`);
  await mint_transaction.wait();
  mint_transaction = await realEstate.connect(seller).mint(`http://127.0.0.1:8080/ipfs/QmSxQx7hh3JvSRppsUwmDxxjXi2GYbc2xk4cwCr9MLgHtH?filename=3.json`);
  await mint_transaction.wait();
  console.log("Minted!")

  //Deploying Escrow Contract
  const Escrow = await ethers.getContractFactory('Escrow');
  const escrow = await Escrow.deploy(realEstate.address, seller.address, inspector.address, lender.address);
  await escrow.deployed();
  console.log(`Deployed Escrow Contract at ${escrow.address}`);

  for (let i = 0; i < 3; i++) {
    const transaction = await realEstate.connect(seller).approve(escrow.address, i+1);
    await transaction.wait();
  }

  console.log(`approved...`);

  transaction = await escrow.connect(seller).list(1, tokens(20), tokens(10), buyer.address);
  await transaction.wait();

  transaction = await escrow.connect(seller).list(2, tokens(15), tokens(5), buyer.address);
  await transaction.wait();

  transaction = await escrow.connect(seller).list(3, tokens(10), tokens(5), buyer.address);
  await transaction.wait();

  console.log(`Finished!`);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
