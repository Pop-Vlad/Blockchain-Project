pragma solidity >=0.5.0 <0.6.0;

import "./ownable.sol";
import "./LotteryTokens.sol";

contract Lottery is LotteryTokens, Ownable {
    
    uint256 ticketPrice = 0.001 ether;
    
    uint256 randNonce = 0;
    uint8 retainPrize = 20;
    uint8 exchangeFee = 2;
    
    
    function getPrize() external view returns(uint256) {
        return _totalSupply * ticketPrice * (100 - retainPrize) / 100 * (100 - exchangeFee) / 100;
    }
    
    function getExchangeFee() external view returns(uint8) {
        return exchangeFee;
    }
    
    function getRetainedPrize() external view returns(uint8) {
        return retainPrize;
    }
    
    function getTicketPrice() external view returns(uint256) {
        return ticketPrice;
    }
    
    
    
    
    function buyTickets(uint256 nrTickets) external payable {
        require(msg.value >= ticketPrice * nrTickets);
        _balances[msg.sender] += nrTickets;
        uint256 rest = msg.value - ticketPrice * nrTickets;
        if (rest > 0){
            msg.sender.transfer(rest);
        }
    }
    
    
    
    function tryTicket(uint8[] calldata numbers) external {
        require(_balances[msg.sender] >= 1);
        _balances[msg.sender]--;
        _totalSupply++;
        if (checkNumbers(numbers)){
            win();
        }
    }
    
    function win() internal {
        uint256 amountTokensWon = _totalSupply * (100 - retainPrize) / 100;
        _totalSupply -= amountTokensWon;
        uint amountEthToTransfer = amountTokensWon * (100 - exchangeFee) / 100 * ticketPrice;
        msg.sender.transfer(amountEthToTransfer);
    }
    
    function checkNumbers(uint8[] memory numbers) internal returns(bool) {
        uint8[] memory winningNumbers = generateWinningNumbers();
        return equal(numbers, winningNumbers, 5);
    }
    
    function generateWinningNumbers() internal returns(uint8[] memory) {
        uint8[] memory generatedValues;
        for (uint8 i=0; i<5;i++){
            uint8 r = uint8(randMod(50-i));
            for(uint8 j=0; j<i; j++) {
                if(generatedValues[j] < r){
                    r++;
                }
            }
            
            // keep array sorted
            for(uint8 j=0; j<5; j++) {
                if (r > generatedValues[j]) {
                    continue;
                }
                else {
                    uint8 aux = generatedValues[j];
                    generatedValues[j] = r;
                    r = aux;
                    if (r == 0) {
                        break;
                    }
                }
            }
        }
        return generatedValues;
    }
    
    function genTest() external returns(uint8[] memory) {
        uint8[] memory generatedValues;
        for (uint8 i=0; i<5;i++){
            uint8 r = uint8(randMod(50-i));
            for(uint8 j=0; j<i; j++) {
                if(generatedValues[j] < r){
                    r++;
                }
            }
            
            // keep array sorted
            for(uint8 j=0; j<5; j++) {
                if (r > generatedValues[j]) {
                    continue;
                }
                else {
                    uint8 aux = generatedValues[j];
                    generatedValues[j] = r;
                    r = aux;
                    if (r == 0) {
                        break;
                    }
                }
            }
        }
        return generatedValues;
    }
    
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
    
    function randMod(uint _modulus) internal returns(uint) {
        randNonce++;
        return uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % _modulus;
    }
    
    
    
    function withdrawEarnings(uint256 _amount) external onlyOwner {
        uint256 reservedBalance = _totalSupply * (100 - exchangeFee) / 100 * ticketPrice;
        require(_amount <= address(this).balance - reservedBalance);
        address payable _owner = address(uint160(owner()));
        _owner.transfer(_amount);
    }
    
    function boostPrize() external payable {
        uint nrTickets = msg.value / ticketPrice;
        _totalSupply += nrTickets;
        uint256 rest = msg.value - ticketPrice * nrTickets;
        if (rest > 0){
            msg.sender.transfer(rest);
        }
    }
    
    
    
    function updateFee(uint8 newFee) external onlyOwner {
        require(newFee <= 5);
        exchangeFee = newFee;
    }
    
    function updateRetainedPrize(uint8 newRetainedPrize) external onlyOwner {
        require(newRetainedPrize <= 30 &&  newRetainedPrize >= 10);
        retainPrize = newRetainedPrize;
    }
}





