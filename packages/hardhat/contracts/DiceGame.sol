// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "./DiceGameFactory.sol"; 
contract DiceGame is DiceGameFactory{ 

  event BetPlaced(address _from, uint _gameId, uint _value);


  function placeBet() public payable {
    require(msg.value > 0, "must be greater than 0");
    uint gameId = userToGameId[msg.sender];
    require(getStatus(gameId) == Status.BetsPending, "Bets are not being placed right now");
    uint userIndex = userToIndex[msg.sender];
    Game storage game = games[gameId];
    game.bet[userIndex] += msg.value;
    bool allBetsPlaced = true;
    for (uint i; i < game.scores.length - 1; i++) {
      if (game.scores[i] => 50) {
        allBetsPlaced = false
        return
      }
    if (allBetsPlaced) {
      game.currentStatus = Status.ScoresPending
    }
    }
    emit BetPlaced(msg.sender, gameId, msg.value);
  }

  function setScore(uint _gameId, uint8 _score) public {
    require(getStatus(_gameId) == Status.ScoresPending, "This action cannot be performed right now");
    Game storage game = games[_gameId];
    game.scores[userToIndex[msg.sender]] = _score;
    if (game.lowScore > _score) {
      game.lowScore = _score;
      game.winner = msg.sender;
    }
    for (uint i; i < game.scores.length; i++) {
      if (game.scores[i] >= 50) {
        
      } 
    }
    if (userToIndex[msg.sender] == game.scores.length - 1) {
      game.currentStatus = Status.Payment;
    }
  }

  function getTotalBet(uint _gameId) public view returns(uint){
    uint totalBet;
    for (uint i; i < games[_gameId].players.length; i++) {
      if (i <= games[_gameId].bet.length - 1) {
        totalBet += games[_gameId].bet[i];
      }
    }
    return totalBet;
  }

  function checkBet(uint _gameId) public view returns(uint) {
    return getTotalBet(_gameId);
  }

  function resetScores(Game storage _game) internal {
      for ( uint i; i < _game.scores.length; i++) {
          _game.scores[i] = uint8(100);
      }
  }

  function resetBets(Game storage _game) internal {
      for (uint i; i < _game.players.length; i++) {
        if (i <= _game.bet.length - 1) {
        _game.bet[i] = 0;
      }
    }
  }

  function resetGame(Game storage _game) internal {
    resetScores(_game);
    resetBets(_game);
    _game.lowScore = 50;
    _game.currentStatus = Status.BetsPending;
  }

  function payWinner(uint _gameId) public payable {
    require(getStatus(_gameId) == Status.Payment, "Game has not ended");
    Game storage game = games[_gameId];
    uint totalBet = getTotalBet(_gameId);
    resetGame(game);
    (bool sent, bytes memory data) = game.winner.call{value: totalBet}("");
    require(sent, "Failed to send Ether to winner");
    emit GameSet(game, "game over");
  }
  }