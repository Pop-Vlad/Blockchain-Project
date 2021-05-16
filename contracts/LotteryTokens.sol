pragma solidity >=0.5.0 <0.6.0;

import "./ERC20.sol";

contract LotteryTokens is ERC20 {
    
    function balanceOfOwner(address account) external view returns (uint256) {
        return super.balanceOf(account);
    }
    
    function addTokensToReceiver(address receiver, uint256 tokens) internal returns (bool) {
        super._mint(receiver, tokens);
        return true;
    }
    
    function getPool() external view returns (uint256) {
        return totalSupply();
    }
    
    function transferTokens(address recipient, uint256 amount) internal {
        uint256 value = super.balanceOf(msg.sender);
        require(value >= amount);
        super.transfer(recipient,amount);
    }
}