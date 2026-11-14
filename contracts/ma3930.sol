// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISwap.sol";
import "./sAsset.sol";

contract Swap is Ownable, ISwap {

    address token0;
    address token1;
    uint reserve0;
    uint reserve1;
    mapping (address => uint) shares;
    uint public totalShares;

    constructor(address addr0, address addr1) {
        token0 = addr0;
        token1 = addr1;
    }

    function init(uint token0Amount, uint token1Amount) external override onlyOwner {
        require(reserve0 == 0 && reserve1 == 0, "init - already has liquidity");
        require(token0Amount > 0 && token1Amount > 0, "init - both tokens are needed");
        
        require(sAsset(token0).transferFrom(msg.sender, address(this), token0Amount));
        require(sAsset(token1).transferFrom(msg.sender, address(this), token1Amount));
        reserve0 = token0Amount;
        reserve1 = token1Amount;
        totalShares = sqrt(token0Amount * token1Amount);
        shares[msg.sender] = totalShares;
    }

    // https://github.com/Uniswap/v2-core/blob/v1.0.1/contracts/libraries/Math.sol
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function getReserves() external view returns (uint, uint) {
        return (reserve0, reserve1);
    }

    function getTokens() external view returns (address, address) {
        return (token0, token1);
    }

    function getShares(address LP) external view returns (uint) {
        return shares[LP];
    }

    /* TODO: implement your functions here */
    function addLiquidity(uint token0Amount) external override{
        require(reserve0 > 0 && reserve1 > 0, "Pool not initialized");
        require(token0Amount > 0, "token0Amount must be greater than 0");

        uint token1Amount = (reserve1 * token0Amount) / reserve0;
        require(token1Amount > 0, "token1Amount must be greater than 0");

        uint new_LP_shares = (totalShares * token0Amount) / reserve0;
        require(new_LP_shares > 0, "new_LP_shares must be sufficient (>0)");

        require(sAsset(token0).transferFrom(msg.sender, address(this), token0Amount), "Transfer token0 failed");
        require(sAsset(token1).transferFrom(msg.sender, address(this), token1Amount), "Transfer token1 failed");

        reserve0 += token0Amount;
        reserve1 += token1Amount;
        totalShares += new_LP_shares;
        shares[msg.sender] += new_LP_shares;
    }

    function removeLiquidity(uint withdrawShares) external override{
        require(reserve0 > 0 && reserve1 > 0, "Pool not initialized");
        require(withdrawShares > 0, "Shares must be > 0");
        require(shares[msg.sender] >= withdrawShares, "insufficient shares");
        require(totalShares > 0, "totalShares must be > 0");

        uint amount0 = reserve0 * withdrawShares / totalShares;
        uint amount1 = reserve1 * withdrawShares / totalShares;

        require(amount0 > 0 && amount1 > 0, "required token amounts too low");
        shares[msg.sender] -= withdrawShares;
        totalShares -= withdrawShares;
        reserve0 -= amount0;
        reserve1 -= amount1;

        require(sAsset(token0).transfer(msg.sender, amount0), "Transfer token0 failed");
        require(sAsset(token1).transfer(msg.sender, amount1), "Transfer token1 failed");

    }

    function token0To1(uint token0Amount) external override{
        require(reserve0 > 0 && reserve1 > 0, "Pool not initialized");
        require(token0Amount > 0, "token0Amount must be greater than 0");

        // handle 997/1000 instead of 0.3% fee
        // (reserve0 + token0_to_exchange) * (reserve1 - token_1_out) = invariant
        uint token1_to_return = (token0Amount * 997 * reserve1) / (reserve0 * 1000 + token0Amount * 997);

        require(token1_to_return > 0, "Insufficient output of token1 amount");
        require(token1_to_return < reserve1, "Insufficient liquidity in pool");
        
        require(sAsset(token0).transferFrom(msg.sender, address(this), token0Amount), "Transfer token0 failed");
        require(sAsset(token1).transfer(msg.sender, token1_to_return), "Transfer token1 failed");

        reserve0 += token0Amount;
        reserve1 -= token1_to_return;
 
    }

    function token1To0(uint token1Amount) external override{
        require(reserve0 > 0 && reserve1 > 0, "Pool not initialized");
        require(token1Amount > 0, "token0Amount must be greater than 0");

        // handle 997/1000 instead of 0.3% fee
        // token1Out = reserve1 - (reserve0 * reserve1) / (reserve0 + token0_to_exchange)
        uint token0_to_return = (token1Amount * 997 * reserve0) / (reserve1 * 1000 + token1Amount * 997);

        require(token0_to_return > 0, "Insufficient output of token0");
        require(token0_to_return < reserve0, "Insufficient liquidity in pool");
        
        require(sAsset(token1).transferFrom(msg.sender, address(this), token1Amount), "Transfer token1 failed");
        require(sAsset(token0).transfer(msg.sender, token0_to_return), "Transfer token0 failed");

        reserve1 += token1Amount;
        reserve0 -= token0_to_return;

    }

    
}