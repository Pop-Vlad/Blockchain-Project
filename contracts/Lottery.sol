pragma solidity >=0.5.0 <0.6.0;

import "./ownable.sol";
import "./LotteryTokens.sol";

contract Lottery is LotteryTokens, Ownable {
    
    uint256 ticketPrice = 0.001 ether;
    
    uint256 randNonce = 0;
    uint8 retainPrize = 20;
    uint8 exchangeFee = 2;
    
    /**
    * @dev Returns an integer value indicating the prize pool in ETH(80% of the `_totalSupply` with 2% `exchangeFee` by default).
    */
    function getPrize() external view returns(uint256) {
        return _totalSupply * ticketPrice * (100 - retainPrize) / 100 * (100 - exchangeFee) / 100;
    }
    
    /**
    * @dev Returns an integer value indicating the current `exchangeFee`(2% by default).
    */
    function getExchangeFee() external view returns(uint8) {
        return exchangeFee;
    }
    
    /**
    * @dev Returns an integer value indicating the current `retainPrize`(20% by default), which will be held for the next prize pool, after someone wins the current one.
    */
    function getRetainedPrize() external view returns(uint8) {
        return retainPrize;
    }
    
    /**
    * @dev Returns an integer value indicating the current `ticketPrice`(0.001 ETH by default).
    */
    function getTicketPrice() external view returns(uint256) {
        return ticketPrice;
    }
    
    
    
    
    /**
    * @dev Adds a token to the balance of the function caller if the price was paid and moves the surplus back to the sender if they paid too much.
    */
    function buyTickets(uint256 nrTickets) external payable {
        // the value sent covers the price of the tickets
        require(msg.value >= ticketPrice * nrTickets);
        _balances[msg.sender] += nrTickets;
        uint256 rest = msg.value - ticketPrice * nrTickets;
        if (rest > 0){
            // send the rest back
            msg.sender.transfer(rest);
        }
    }
    
    
    
    
    /**
    * @dev Moves a token from the balance of the function caller and adds it to the `_totalSupply`.
    *
    * @dev Checks if the `numbers` are the same as the 5 randomly generated numbers.
    *
    * Calls function `equal()` to check if the 2 sets of numbers are the same.
    *
    * Calls win() if the numbers are the same as the ones generated.
    */
    function tryTicket(uint8[] calldata numbers) external returns(bool, uint8[] memory) {
        require(_balances[msg.sender] >= 1);
        _balances[msg.sender]--;
        _totalSupply++;
        
        // generate the winning numbers
        uint8[] memory winningNumbers = generateRandomDistinctNumbers(5, 50);
        bool won = false;
        if (equal(numbers, winningNumbers, 5)){
            // the ticket won
            won = true;
            win();
        }
        return (won, winningNumbers);
    }
    
    /**
    * @dev Moves a percentage(80% by default) from the `_totalSupply` to the caller of the function, converted in ETH with a fee(2% by default).
    */
    function win() internal {
        // calculate won amount
        uint256 amountTokensWon = _totalSupply * (100 - retainPrize) / 100;
        _totalSupply -= amountTokensWon;
        uint amountEthToTransfer = amountTokensWon * (100 - exchangeFee) / 100 * ticketPrice;
        // send prize to the user account
        msg.sender.transfer(amountEthToTransfer);
    }
    
    
    /**
    * @dev Generates an array with randomly generated values which are distinct and are sorted in ascending order.
    * The number of generated numbers is _sampleSize. The numbers are picked from {1, 2, ..., _domainSize}
    *
    * Returns the generated array.
    */
    function generateRandomDistinctNumbers(uint8 _sampleSize, uint8 _domainSize) internal returns(uint8[] memory) {
        uint8[] memory generatedValues = new uint8[](_sampleSize);
        for (uint8 i=0; i<_sampleSize;i++){
            
            // generate a random number r
            uint8 r = uint8(randMod(_domainSize-i)) + 1;
            // increase r by 1 fo each value smaller than r.
            for(uint8 j=0; j<i; j++) {
                if(generatedValues[j] < r){
                    r++;
                }
            }
            
            // Add r to generatedValues
            // keep array sorted after each addition
            for(uint8 j=0; j<i; j++) {
                if (r < generatedValues[j]) {
                    uint8 aux = generatedValues[j];
                    generatedValues[j] = r;
                    r = aux;
                }
            }
            generatedValues[i] = r;
        }
        return generatedValues;
    }
    
    /**
    * @dev Checks whether the arrays of numbers are the same.
    *
    * Returns a boolean value indicating whether the 2 given arrays are the same or not.
    */
    function equal(uint8[] memory a, uint8[] memory b, uint8 n) internal pure returns(bool) {
        bool ok;
        for(uint8 i=0; i<n; i++) {
            ok = false;
            for (uint8 j=0; j<n; j++) {
                if (a[i] == b[j]) {
                    ok = true;
                    break;
                }
                
            }
            if (ok == false)
                return false;
        }
        return true;
    }
    
    /**
    * @dev Returns a randomly generated integer.
    */
    function randMod(uint _modulus) internal returns(uint) {
        randNonce++;
        return uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % _modulus;
    }
    
    
    
    /**
    * @dev Moves the earned amount of wei from the contract to the caller's account.
    *
    * Only the owner can withdraw and can't withdraw from the prize pool.
    * Returns the amount transfered.
    */
    function withdrawEarnings() external onlyOwner returns(uint256) {
        uint256 reservedBalance = _totalSupply * (100 - exchangeFee) / 100 * ticketPrice;
        uint256 _amount = address(this).balance - reservedBalance;
        address payable _owner = address(uint160(owner()));
        _owner.transfer(_amount);
        return _amount;
    }
    
    /**
    * @dev Adds tokens to the `__totalSupply` after the price was paid. The payer won't recieve anything in exchange.
    *
    * Returns an integer indicating the number of tokens that were added to the _totalSupply.
    */
    function boostPrize() external payable returns(uint256) {
        uint256 nrTickets = msg.value / ticketPrice;
        _totalSupply += nrTickets;
        uint256 rest = msg.value - ticketPrice * nrTickets;
        if (rest > 0){
            msg.sender.transfer(rest);
        }
        return nrTickets;
    }
    
    
    
    /**
    * @dev Changes the current `exchangeFee` to the `newFee`.
    *
    * It can be called only by the owner.
    */
    function updateFee(uint8 newFee) external onlyOwner returns(uint8) {
        require(newFee <= 5);
        exchangeFee = newFee;
        return exchangeFee;
    }
    
    /**
    * @dev Changes the current `retainPrize` to the `newRetainedPrize`.
    *
    * It can be called only by the owner and can't be greater than 30 and less than 10.
    */
    function updateRetainedPrize(uint8 newRetainedPrize) external onlyOwner returns(uint8) {
        require(newRetainedPrize <= 30 &&  newRetainedPrize >= 10);
        retainPrize = newRetainedPrize;
        return retainPrize;
    }
}





