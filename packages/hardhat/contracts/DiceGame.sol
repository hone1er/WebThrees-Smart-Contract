// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "./DiceGameFactory.sol"; 
contract DiceGame is DiceGameFactory{ 

  event BetPlaced(address indexed _from, uint _gameId, uint _value);


  function placeBet() public payable {
    require(msg.value > 0, "must be greater than 0");
    uint gameId = userToGameId[msg.sender];
    uint userIndex = userToIndex[msg.sender];
    Game storage game = games[gameId];
    game.bet[userIndex] += msg.value;
    if (userToIndex[msg.sender] == game.scores.length - 1) {
      game.currentStatus = Status.ScoresPending;
    }
    emit BetPlaced(msg.sender, gameId, msg.value);
  }

  function setScore(uint _gameId, uint8 _score) public {
    require(getStatus(_gameId) == Status.ScoresPending, "Bets are not being placed currently");
    Game storage game = games[_gameId];
    game.scores[userToIndex[msg.sender]] = _score;
    if (game.lowScore > _score) {
      game.lowScore = _score;
      game.winner = msg.sender;
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
    resetBets(game);
    _game.lowScore = 100;
    _game.currentStatus = Status.BetsPending;
  }

  function payWinner(uint _gameId) public {
    require(getStatus(_gameId) == Status.Payment, "Game has not ended");
    Game storage game = games[_gameId];
    uint totalBet = getTotalBet(_gameId);
    resetGame(game);
    payable(game.winner).call{value: totalBet};
    emit GameSet(game, "game over");
  }
  }