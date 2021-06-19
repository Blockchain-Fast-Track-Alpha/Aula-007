// SPDX-License-Identifier: GPL-3.0

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

pragma solidity >=0.8.0 <0.9.0;

interface IGovernedGameAdmin {
    function setProposalFactoryAddress(address newAddress) external;
}

contract GovernedGameAdmin is Context, IGovernedGameAdmin {
    address public gameAddress;
    address public gameCurrencyAddress;
    uint256 public proposalCost;
    uint256 public votingDuration;

    address public proposalFactoryAddress;

    address public protocolUpdateProposalAddress;

    event ProposalCreated(uint256 indexed timestamp, address proposal);

    constructor(
        address _gameAddress,
        address _gameCurrencyAddress,
        uint256 initialProposalCost,
        uint256 initialVotingDuration,
        address initialProposalFactoryAddress
    ) {
        gameAddress = _gameAddress;
        gameCurrencyAddress = _gameCurrencyAddress;
        proposalCost = initialProposalCost;
        votingDuration = initialVotingDuration;
        proposalFactoryAddress = initialProposalFactoryAddress;
    }

    function setProposalFactoryAddress(address newAddress) public override {
        require(
            protocolUpdateProposalAddress == _msgSender(),
            "Only the proposal may update the protocol"
        );
        proposalFactoryAddress = newAddress;
        protocolUpdateProposalAddress = address(0);
    }

    function proposeChangeProposalCost() public {
        //TODO
    }

    function proposeChangeVotingDuration() public {
        //TODO
    }

    function proposeChangeGameOdds() public {
        //TODO
    }

    function proposeUpdateProtocol(address proposal) public {
        require(
            protocolUpdateProposalAddress == address(0),
            "Protocol update already in progress"
        );
        //TODO: implement proposal cost
        // ---------------(SPOILER)-----------------
        // IERC20(gameCurrencyAddress).transferFrom(
        //     _msgSender(),
        //     gameAddress,
        //     proposalCost
        // );
        // -------------(END SPOILER)---------------
        emit ProposalCreated(block.timestamp, proposal);
        protocolUpdateProposalAddress = IProposalFactory(proposalFactoryAddress)
            .createProposal("UPDATE PROTOCOL", votingDuration, proposal);
    }

    function activeProposalVersion() public view returns (uint256) {
        return
            protocolUpdateProposalAddress == address(0)
                ? 0
                : IProposal(protocolUpdateProposalAddress).VERSION();
    }

    function activeProposalLogic(
        uint256 valA,
        uint256 valB,
        uint256 valC
    ) public view returns (uint256) {
        return
            protocolUpdateProposalAddress == address(0)
                ? 0
                : IProposal(protocolUpdateProposalAddress).doSomeLogic(
                    valA,
                    valB,
                    valC
                );
    }
}

interface IProposal {
    function VERSION() external view returns (uint256);

    function originAddress() external view returns (address);

    function proposedChange() external view returns (address);

    function doSomeLogic(
        uint256 valA,
        uint256 valB,
        uint256 valC
    ) external pure returns (uint256);

    function processVotingResult() external;
}

interface IProposalFactory {
    function createProposal(
        string memory name,
        uint256 duration,
        address newProtocol
    ) external returns (address);
}

contract ProposalV01 is IProposal {
    uint256 public constant override VERSION = 1;
    address public override originAddress;

    address public override proposedChange;

    constructor(address _proposedChange, address _originAddress) {
        originAddress = _originAddress;
        proposedChange = _proposedChange;
    }

    function doSomeLogic(
        uint256 valA,
        uint256 valB,
        uint256 valC
    ) public pure override returns (uint256 result) {
        result = valB;
        result = 2 * valA + result / 2;
        result = (valC + result) / 2;
    }

    function processVotingResult() public override {
        //TODO: Require voting passed
        IGovernedGameAdmin(originAddress).setProposalFactoryAddress(
            proposedChange
        );
    }
}

contract ProposalV02 is IProposal {
    uint256 public constant override VERSION = 2;
    address public override originAddress;

    address public override proposedChange;

    constructor(address _proposedChange, address _originAddress) {
        originAddress = _originAddress;
        proposedChange = _proposedChange;
    }

    function doSomeLogic(
        uint256 valA,
        uint256 valB,
        uint256 valC
    ) public pure override returns (uint256 result) {
        result = (valA + valC) / 2;
        result = 5 * valB + result / 9;
        result = (valA + 3 * valB + valC / 3 + result) / 3;
    }

    function processVotingResult() public override {
        //TODO: Require voting passed
        IGovernedGameAdmin(originAddress).setProposalFactoryAddress(
            proposedChange
        );
    }
}

contract ProposalV01Factory is IProposalFactory, Context {
    function createProposal(
        string memory name,
        uint256 duration,
        address newProtocol
    ) public override returns (address) {
        return address(new ProposalV01(newProtocol, _msgSender()));
    }
}

contract ProposalV02Factory is IProposalFactory, Context {
    function createProposal(
        string memory name,
        uint256 duration,
        address newProtocol
    ) public override returns (address) {
        return address(new ProposalV02(newProtocol, _msgSender()));
    }
}
