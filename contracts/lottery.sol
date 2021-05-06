pragma solidity >=0.5.0 <0.6.0;

import "./ownable.sol";

contract Lottery is Ownable {
    
    mapping (address => uint256) tokensOwned;
    uint256 prizePool;
    uint256 fees;
    
    uint randNonce = 0;
    uint8 retainPrize = 10;
    uint8 exchangeFee = 2;
    
    function tryTicket(uint[] calldata numbers) external {
        require(tokensOwned[msg.sender] >= 1);
        tokensOwned[msg.sender]--;
        prizePool++;
        if (checkNumbers(numbers)){
            win();
        }
    }
    
    function win() internal {
        uint256 amount = prizePool * (100 - retainPrize) / 100;
        prizePool -= amount;
        tokensOwned[msg.sender] += amount;
        fees += prizePool * exchangeFee / 100;
    }
    
    function checkNumbers(uint[] memory numbers) internal returns(bool){
        for (uint8 i=0; i<5;i++){
            uint256 r = randMod(50);
            if (numbers[i] == r){
                return false;
            }
        }
        return true;
    }
    

    function randMod(uint _modulus) internal returns(uint) {
        randNonce++;
        return uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % _modulus;
    }
    
  function withdraw(uint256 _amount) external onlyOwner {
    require(_amount < fees);
    address payable _owner = address(uint160(owner()));
    _owner.transfer(_amount);
  }
  
  function boostPrize() external payable {
  }
}