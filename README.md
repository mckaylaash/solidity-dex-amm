# Building a DEX Platform

A decentralized exchange (DEX) peer-to-peer marketplace built using Solidity smart contracts. This protocol is derived from **Uniswap v2**, utilizing the constant product market maker model ($x \cdot y = k$) and liquidity pools to facilitate token exchanges and reward liquidity providers.

---

## Overview & Architecture

Unlike traditional order book exchanges, this DEX uses an automated market maker (AMM) model where token prices are determined deterministically by a mathematical formula rather than matching buyers and sellers directly.

* **Constant Product Formula:** $reserve_0 \cdot reserve_1 = invariant$ (or $k$)
* **Liquidity Pools:** Pools of two token assets (`token0` and `token1`) locked in a smart contract.
* **LP Tokens (Shares):** Issued proportionally to investors who deposit assets, representing their share of the pool and entitling them to claim a pro-rata portion of accumulated trading fees.

---

## Contract Specification (`contracts/Swap.sol`)

### State Variables
- `token0` / `token1`: Contract addresses of the trading pair.
- `reserve0` / `reserve1`: Current token reserves held in the pool.
- `totalShares`: Total number of LP shares issued.
- `shares`: Mapping from a liquidity provider's address to their owned shares.

### Core Functions
1. **`init`**: Used by the initial liquidity provider to set the starting ratio and price of the tokens. Shares minted are calculated as $\text{shares} = \sqrt{\text{amount}_0 \cdot \text{amount}_1}$.
2. **`addLiquidity`**: Allows subsequent liquidity providers to deposit equivalent values of both tokens based on the current reserve ratio, issuing proportional pool shares.
3. **`token0To1` / `token1To0`**: Executes token swaps while maintaining the constant product invariant. Automatically deducts a **0.3% protocol fee**, which remains in the pool to benefit liquidity providers.
4. **`removeLiquidity`**: Allows liquidity providers to burn their shares and withdraw their proportional slice of the underlying reserves (including accumulated fees).
5. **View Helpers**: Includes `getReserves`, `getTokens`, `getShares`, and a square root helper (`sqrt`).

---

## Getting Started & Testing

This project uses **Truffle** for smart contract compilation and testing, and **Ganache** for a local blockchain simulation.

