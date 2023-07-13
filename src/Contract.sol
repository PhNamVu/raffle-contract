// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@thirdweb-dev/contracts/base/ERC721Base.sol";

contract NFTRaffleContract {
    bool public raffleStatus;
    address public owner;

    mapping(address => uint256) public entryCount;
    address[] public players;
    address[] private playerSelector;

    uint256 public entryCost;
    uint256 public totalEntries;
    address public nftAddress;
    uint256 public nftId;

    event NewEntry(address player);
    event RaffleStarted();
    event RaffleEnded();
    event WinnerSelected(address winner);
    event EntryCostChanged(uint256 newCost);
    event NFTPrizeSet(address nftAddress, uint256 nftId);
    event BalanceWithdrawn(uint256 amount);

    constructor(uint256 _entryCost) {
        owner = msg.sender;
        entryCost = _entryCost;
        raffleStatus = false;
        totalEntries = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function startRaffle(
        address _nftContract,
        uint256 _tokenId
    ) public onlyOwner {
        require(!raffleStatus, "Raffle is aldready started");
        require(
            nftAddress == address(0),
            "NFT prize already set. Please select winner from pool"
        );
        require(
            ERC721Base(_nftContract).ownerOf(_tokenId) == address(this),
            "Contract does not own the NFT"
        );

        nftAddress = _nftContract;
        nftId = _tokenId;
        raffleStatus = true;

        emit RaffleStarted();
        emit NFTPrizeSet(nftAddress, nftId);
    }

    function buyEntry(uint256 _numberOfEntries) public payable {
        require(raffleStatus, "Raffle is not started");
        require(msg.value == entryCost * _numberOfEntries, "Incorrect amount");

        entryCount[msg.sender] += _numberOfEntries;
        totalEntries += _numberOfEntries;

        if (!isPlayer(msg.sender)) {
            players.push(msg.sender);
        }
    }

    function isPlayer(address _player) public view returns (bool) {
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == _player) {
                return true;
            }
            return false;
        }
    }

    function endRaffle() public onlyOwner {
        require(raffleStatus, "Raffle is not started");
        raffleStatus = false;
        emit RaffleEnded();
    }

    function selectWinner() public onlyOwner {
        require(!raffleStatus, "Raffle is still running");
        require(playerSelector.length > 0, "No player in raffle");
        require(nftAddress != address(0), "NFT prize not set");

        uint256 winnerIndex = random() % playerSelector.length;
        address winner = playerSelector[winnerIndex];

        emit WinnerSelected(winner);

        ERC721Base(nftAddress).transferFrom(owner, winner, nftId);

        resetEntryCount();

        nftAddress = address(0);
        nftId = 0;
        totalEntries = 0;

        delete playerSelector;
    }

    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.prevrandao,
                        block.timestamp,
                        players.length
                    )
                )
            );
    }

    function resetEntryCount() private {
        for (uint256 i = 0; i < players.length; i++) {
            delete entryCount[players[i]];
        }
    }

    function changeEntryCost(uint256 _newCost) public onlyOwner {
        require(!raffleStatus, "Raffle is still running");
        entryCost = _newCost;
        emit EntryCostChanged(entryCost);
    }

    function withdrawBalance() public onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw");

        uint256 balanceAmount = address(this).balance;

        payable(owner).transfer(balanceAmount);
        emit BalanceWithdrawn(balanceAmount);
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function resetContract() public onlyOwner {
        delete playerSelector;
        delete players;
        raffleStatus = false;
        nftAddress = address(0);
        nftId = 0;
        totalEntries = 0;
        entryCost = 0;
        resetEntryCount();
    }
}
