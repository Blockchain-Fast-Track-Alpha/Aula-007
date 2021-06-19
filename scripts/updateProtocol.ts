import console from "console";
import { ethers } from "hardhat";

async function main() {
  const [
    GovernedGameAdminContractFactory,
    ProposalV01FactoryContractFactory,
    ProposalV02FactoryContractFactory,
  ] = await Promise.all([
    ethers.getContractFactory("GovernedGameAdmin"),
    ethers.getContractFactory("ProposalV01Factory"),
    ethers.getContractFactory("ProposalV02Factory"),
  ]);
  const [ProposalV01FactoryContract, ProposalV02FactoryContract] =
    await Promise.all([
      ProposalV01FactoryContractFactory.deploy(),
      ProposalV02FactoryContractFactory.deploy(),
    ]);
  await Promise.all([
    ProposalV01FactoryContract.deployed(),
    ProposalV02FactoryContract.deployed(),
  ]);
  const GovernedGameAdminContract =
    await GovernedGameAdminContractFactory.deploy(
      ethers.constants.AddressZero,
      ethers.constants.AddressZero,
      0,
      0,
      ProposalV01FactoryContract.address
    );
  await GovernedGameAdminContract.deployed();
  console.log({
    GovernedGameAdminContractAddress: GovernedGameAdminContract.address,
    ProposalV01FactoryContractAddress: ProposalV01FactoryContract.address,
    ProposalV02FactoryContractAddress: ProposalV02FactoryContract.address,
    GovernedGameAdminContractProposalFactoryAddress:
      await GovernedGameAdminContract.proposalFactoryAddress(),
  });
  const newProposal = ProposalV02FactoryContract.address;
  console.log("Proposing " + newProposal + " as the new ProposalFactory");
  await GovernedGameAdminContract.proposeUpdateProtocol(newProposal);
  const proposalV01ToV02Address =
    await GovernedGameAdminContract.protocolUpdateProposalAddress();
  console.log("Proposal sent using V01");
  console.log({
    proposalAddress: proposalV01ToV02Address,
    version: (
      await GovernedGameAdminContract.activeProposalVersion()
    ).toString(),
    logicResult: (
      await GovernedGameAdminContract.activeProposalLogic(1, 2, 3)
    ).toString(),
  });
  const ProposalInterfaceContract = await ethers.getContractAt(
    "IProposal",
    proposalV01ToV02Address
  );
  console.log(
    "Proposal address before voting result: " +
      (await GovernedGameAdminContract.protocolUpdateProposalAddress())
  );
  await ProposalInterfaceContract.processVotingResult();
  console.log("Voting proposal passed and result is processed");
  console.log({
    GovernedGameAdminContractAddress: GovernedGameAdminContract.address,
    ProposalV01FactoryContractAddress: ProposalV01FactoryContract.address,
    ProposalV02FactoryContractAddress: ProposalV02FactoryContract.address,
    GovernedGameAdminContractProposalFactoryAddress:
      await GovernedGameAdminContract.proposalFactoryAddress(),
  });
  console.log(
    "Proposal address after voting result and before another proposal: " +
      (await GovernedGameAdminContract.protocolUpdateProposalAddress())
  );
  await GovernedGameAdminContract.proposeUpdateProtocol(
    ProposalV01FactoryContract.address
  );
  console.log(
    "Proposing " +
      ProposalV01FactoryContract.address +
      " as the new ProposalFactory"
  );
  const proposalV02ToV01Address =
    await GovernedGameAdminContract.protocolUpdateProposalAddress();
  console.log("Proposal sent using V02");
  console.log({
    proposalAddress: proposalV02ToV01Address,
    version: (
      await GovernedGameAdminContract.activeProposalVersion()
    ).toString(),
    logicResult: (
      await GovernedGameAdminContract.activeProposalLogic(1, 2, 3)
    ).toString(),
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
