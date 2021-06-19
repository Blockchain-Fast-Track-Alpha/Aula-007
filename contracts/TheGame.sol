// SPDX-License-Identifier: GPL-3.0

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

pragma solidity >=0.8.0 <0.9.0;

interface IGameCurrencyFactory {
    function createToken(string memory _name, string memory _symbol)
        external
        returns (address);
}

interface IGameCurrency {
    function mint(address to, uint256 amount) external;
}

contract GameCurrency is ERC20, AccessControl {
    constructor(
        string memory _name,
        string memory _symbol,
        address admin
    ) ERC20(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function mint(address to, uint256 amount) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Caller is not a minter"
        );
        _mint(to, amount);
    }

    //TODO: Restrict transfers to only allow player <-> player and player <-> game
}

contract GameCurrencyFactory is IGameCurrencyFactory {
    function createToken(string memory _name, string memory _symbol)
        public
        override
        returns (address)
    {
        return address(new GameCurrency(_name, _symbol, msg.sender));
    }
}

contract TheGame is AccessControl {
    address public gameCurrencyAddress;
    uint8 public odds;

    address public playerTurn;
    uint256 public roundExpiration;

    uint256 public proposalPrice;

    constructor(
        address _gameCurrencyFactoryAddress,
        address _tableAdmin,
        address[] memory _players,
        uint256 startingTokens,
        uint8 initialOdds,
        uint256 roundDuration
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _tableAdmin);
        gameCurrencyAddress = IGameCurrencyFactory(_gameCurrencyFactoryAddress)
            .createToken("NAME", "SYMBOL");
        for (uint256 i = 0; i < _players.length; i++) {
            IGameCurrency(gameCurrencyAddress).mint(
                _players[i],
                startingTokens
            );
        }
        IGameCurrency(gameCurrencyAddress).mint(
            address(this),
            startingTokens * _players.length
        );
        //TODO: setup player roles
        //TODO: setup initial state
        //TODO: setup first round for _players[0]
    }

    function changeOdds(uint8 newOdds) public {
        //TODO: require admin
        //TODO: odds = newOdds;
    }

    function passRound() public {
        //TODO: check if round expired
        //TODO: if expired, proceed to next player and update round expiration date
    }

    function throwCoins(uint256 betAmount) public {
        //TODO: check if message sender has the current round
        //TODO: transfer betAmount of GameCurrency from player to this contract
        bytes32 betEntropy =
            keccak256(
                abi.encode(
                    blockhash(0),
                    block.timestamp,
                    betAmount,
                    msg.data,
                    roundExpiration
                )
            );
        uint8 countBytes = 0;
        for (uint256 i = 1; i < betEntropy.length; i++) {
            bytes1 step = betEntropy[i];
            if (step >= betEntropy[i - 1]) countBytes++;
        }
        //TODO: proceed to next player and update round expiration date
        if (countBytes < odds) {
            //TODO: transfer betAmount*2 to message sender, or all balance available to transfer if not enough balance
        }
    }

    function amIWinner() public view returns (bool) {
        return
            IERC20(gameCurrencyAddress).balanceOf(_msgSender()) >
            IERC20(gameCurrencyAddress).totalSupply() / 2;
    }
}