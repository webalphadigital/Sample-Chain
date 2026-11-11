const hre = require("hardhat");
async function main() {
  const c = await hre.ethers.deployContract("SampleChain");
  await c.waitForDeployment();
  console.log("CONTRACT_ADDRESS=" + (await c.getAddress()));
  const roles = { COLLECTOR: process.env.COLLECTOR, TRANSPORTER: process.env.TRANSPORTER, LAB: process.env.LAB };
  for (const [name, addr] of Object.entries(roles)) {
    if (!addr) continue;
    await (await c.grantRole(await c[name](), addr)).wait();
    console.log(`${name} -> ${addr}`);
  }
}
main().catch((e) => { console.error(e); process.exit(1); });
