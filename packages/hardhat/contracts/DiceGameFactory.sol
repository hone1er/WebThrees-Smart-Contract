// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; 


/// @title A betting contract where lowest score wins
/// @author Hone1er
/// @notice This is only for use on testnets
/// @dev This contract is not secure. Use at your own risk
/// @custom:experimental This is an experimental contract.
contract DiceGameFactory is Ownable{ 

  event GameSet(Game game, string message);

  uint256 internal gameCounter = 0;


  enum Status { BetsPending, ScoresPending, Payment}


  struct Game {
    address[] players;
    address winner;
    uint8 lowScore;
    uint8[] scores;
    uint256[] bet;
    string roomName;
    bool initialized;
    Status currentStatus;
  }

  mapping (address => uint) internal userToGameId;
  mapping (string => uint) internal roomNameToIndex;
  mapping (address => uint8) internal userToIndex;
  modifier notInGame(uint _gameId) {
    require(_gameId != userToGameId[msg.sender], "Player already in this game");
    _;
  }

  Game[] internal games;


  constructor() {}
    
  receive() external payable { }

  /// @notice Retrieve all games ever created
  /// @return All games in storage
  function getAllGames() public view returns(Game[] memory) {
    return games;
  }

  /// @notice Retrieve a single game object
  /// @param _gameId The ID number/Index number of the game
  /// @return The details of the game
  function getGame(uint _gameId) public view returns(Game memory) {
    return games[_gameId];
  }

  /// @notice Uses room name to retrieve the game index
  /// @param _roomName The name of the room for lookup
  /// @return The index of the game in the games array
  function getGameId(string memory _roomName) public view returns(uint) {
    return roomNameToIndex[_roomName];
  }


  
  /// @notice Adds a new empty game to storage
  /// @dev Must be initialized resulting in two transactions for new games
  function newGame() public {
    address[] memory players;
    address winner;
    uint8[] memory scores;
    uint256[] memory bet;
    string memory roomName;
    
    Game memory game = Game(players, winner, 50, scores, bet, roomName, false, Status.BetsPending);
    games.push(game);
    userToGameId[msg.sender] = gameCounter;
    userToIndex[msg.sender] = uint8(0);
    gameCounter++;
  }

  /// @notice Initializes a new game after creation
  /// @param _gameId The index of the game to be initialized
  /// @param _roomName The name to initialize the new game with
  /// @dev This function is accessed by the setGame function
  function initialize(uint _gameId, string memory _roomName) private {
      Game storage game = games[_gameId];

    if (!game.initialized) {
      game.initialized = true;
      game.players = [msg.sender];
      game.scores = [100];
      game.bet = [0];
      game.roomName = _roomName;
    }
}
  
  /// @notice Set the name and initial parameters of new games
  /// @param _roomName The name to initialize the new game with
  function setGame(string memory _roomName) public {
    uint gameId = userToGameId[msg.sender];
    initialize(gameId, _roomName);
    roomNameToIndex[_roomName] = gameId;
    emit GameSet(games[gameId], "new game");
  }

  /// @notice Join a game already in progress
  /// @param _gameId The index of the game in the games array
  function joinGame(uint _gameId) public notInGame(_gameId){
    Game storage game = games[_gameId];
    require(game.currentStatus == Status.BetsPending, "Cannot join until next round begins");
    userToGameId[msg.sender] = _gameId;
    game.players.push(msg.sender);
    userToIndex[msg.sender] = uint8(game.scores.length);
    game.scores.push(uint8(100));
    game.bet.push(uint(0));
    emit GameSet(game, "joinGame");
  }

  /// @notice Returns the progress of the game
  /// @param _gameId The index of the game in the games array for lookup
  function getStatus(uint _gameId) public view returns (Status) {
    return games[_gameId].currentStatus;
} 

  /// @notice Returns all bets to respective users
  /// @param _gameId The index of the game in the games array for lookup
  function emergencyWithdraw(uint _gameId) public payable onlyOwner {
    Game storage game = games[_gameId];
    for (uint i = 0; i < game.players.length; i++) {
    uint bet = game.bet[i];
    game.bet[i] -= game.bet[i];
    (bool sent, bytes memory data) = game.players[i].call{value: bet}("");
    require(sent, "Failed to send Ether to winner");
    game.scores[i] = 100;
    }
  }
}
