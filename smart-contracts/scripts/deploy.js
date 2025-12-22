async function main() {
  const Crowdfunding = await ethers.getContractFactory("Crowdfunding");
  const contract = await Crowdfunding.deploy();
  await contract.waitForDeployment();
  console.log("Crowdfunding deployed at:", contract.target);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
