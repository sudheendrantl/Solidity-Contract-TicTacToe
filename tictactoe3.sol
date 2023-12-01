// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

contract TicTacToeGame {

    address immutable private _playerOne = msg.sender;
    address private _playerTwo;
    address private _lastPlayed;
    address private _winner;
    uint8 private _turnsTaken;
    bool private _isGameOver;

    mapping(address => string) private _stringmap;

    //GameBoard is a 1D array having the location indexes as 
    /*  
        0   1   2
        3   4   5
        6   7   8
    */
    address[9] private _gameBoard;

    constructor() {
        // this address to string mapping is used to map
        // the players as following
        // move done by player1 -> "x"
        // move done by player2 -> "o" (will be set later once player2 address is known)
        // no moves done -> "-"
        // leading and trailing spaces added, so that we dont
        // need to concatenate spaces later during formatting
        _stringmap[address(0)] = " - ";
        _stringmap[msg.sender] = " x ";
    }

    //Function summarises the status of the game in the string returned 
    function getGameStatus() external view returns (string memory) {
        // this returns a string indicating the status of the game
        // this function provides all what the players need/want to know
        // rather than exposing internal variabes which are kept private
        return (_playerTwo == address(0)) ? "player2 hasn't joined game" :
               (_turnsTaken == 0) ? "no moves made yet" : 
               isWinner(_playerOne) ? "player1 wins" : 
               isWinner(_playerTwo) ? "player2 wins" :
               (_turnsTaken == 9) ? "game drawn" :
               "game in progress" ;
    }

    //Function summarises the status the game in the string returned 
    function getWinner() external view returns (address) {
        // this returns the address of the winner
        // in case there is none, returns address(0)
        return isWinner(_playerOne) ? _playerOne : 
               isWinner(_playerTwo) ? _playerTwo :
               address(0) ;
    }

    //Function will start the game by taking the address of the second player. 
    //The address of the first player will be the same one which will initiate the game.
    function startGame(address _player2) external {
        /*Add you code here*/
        // dont permit player1 and player2 to be the same
        // also dont accept 0 address for player2
        require(_player2!=address(0),"player2 address cannot be 0");
        require(_player2!=_playerOne,"player1 and player2 cannot be same");

        // in case this is not the first game after deployment, cleanup
        // the past mapping that would have been done for the earlier player2
        // this is done to save gas
        if ( _playerTwo != address(0) ){
            delete _stringmap[_playerTwo];
        }

        // as a new game is being started, initialize all state variables
        _playerTwo = _player2;
        _lastPlayed = address(0);
        _winner = address(0);
        _isGameOver = false;
        _turnsTaken = 0;

        for (uint8 i; i<uint8(_gameBoard.length);i++){
            _gameBoard[i] = address(0);
        }

        // as the new player2 address is now known, create a mapping
        // that associates player2 with the symbol "o"
        _stringmap[_playerTwo] = " o ";
    }
    
    //Function for placing the move of the current player on the game board
    function placeMove(uint8 _location) external {

        //This will check if the game is over or is still active by checking the isGameOver flag and the winner address
        require(_isGameOver!=true || _winner==address(0),"game already over");

        //This will check if the game is draw or is still active by checking the isGameOver flag
        require(_isGameOver==false,"game drawn. startGame again");

        //This will check if the transaction is made from some other system(having different address other then that of players) apart from both the players
        require(msg.sender==_playerOne || msg.sender==_playerTwo,"unauthorized player");

        //While placing the move, we will check if the move at the specified location is already taken of not
        require(_location<_gameBoard.length, "invalid location");
        require(_playerTwo!=address(0),"require player2");
        require(_gameBoard[_location]==address(0),"move already done");

        //This condition is to check if the last played player is again the turn or is the turn given to the next player inline
        require(_lastPlayed!=msg.sender,"not your turn");
        
        //Saving the player's address on the required location.
        _gameBoard[_location] = msg.sender;

        //Saving the current player's address in the last played variable so as to keep the track of the latest plater which exercised the move
        _lastPlayed = msg.sender;

        //Tracking the number of turns
        // using unchecked and pre-increment (++i, rather than i++), to save gas
        unchecked{++_turnsTaken;}
        
        //Checking if the game lead to the winner after the current move and accordingly updating the winner and isGameOver flag
        // avoiding the "true == isWinner..." construct to save gas
        if ( isWinner(msg.sender) ){
            _isGameOver = true;
            _winner = msg.sender;
            return;
        }
        
        //For checking if the game is draw
        if (9 == _turnsTaken ){
            _isGameOver = true;
        }
    }

     //Function for checking if we have a winner of the game
    function isWinner(address player) private view returns(bool) {
        //various winning filters in terms of rows, columns and diagonals
        uint8[3][8] memory winningfilters = [
            [0,1,2],[3,4,5],[6,7,8],  // winning row filters
            [0,3,6],[1,4,7],[2,5,8],  // winning column filters
            [0,4,8],[2,4,6]           // winning diagonal filters
        ];
        
        // winner cannot be of 0 address!
        if ( address(0) == player ){
            return false;
        }

        // avoiding the usage of state variables repeatedly 
        // storing them into local variables, to save gas
        uint8 len = uint8(winningfilters.length);
        address tmpPlayer = player;
        for (uint8 i; i<len;i++){
            if ( ( tmpPlayer == _gameBoard[winningfilters[i][0]] ) && 
                 ( tmpPlayer == _gameBoard[winningfilters[i][1]] ) && 
                 ( tmpPlayer == _gameBoard[winningfilters[i][2]] ) ){
                return true;
            }
        }
        return false;
    }

   //Function which returns the game board view 
    function getBoard() external view returns(string memory) {
        // returns a string with the placements/moves that
        // have been done/not-done by the players
        // since it is just 9 cells, avoiding the for-loop.
        // also, using the string.concat function that is
        // available in compiler versions >=0.8.16 
        // instead of the abi.encode functions, to save gas
        return string.concat(_stringmap[_gameBoard[0]],
                             _stringmap[_gameBoard[1]],
                             _stringmap[_gameBoard[2]],
                             " | ",
                             _stringmap[_gameBoard[3]],
                             _stringmap[_gameBoard[4]],
                             _stringmap[_gameBoard[5]],
                             " | ",
                             _stringmap[_gameBoard[6]],
                             _stringmap[_gameBoard[7]],
                             _stringmap[_gameBoard[8]]);
    }    
}