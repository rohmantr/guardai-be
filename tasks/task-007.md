# Task-007: Contract Integration Tests

**Prioritas:** P0
**Dependencies:** 001-006
**Module:** contracts/test/

---

## Objective

Buat integration test yang mensimulasikan end-to-end flow smart contract — dari token detection simulation sampai settlement dan payout.

## Test Scenarios

### Scenario 1: Happy Path — Rug Pull Terjadi

1. Deploy semua contracts (PredictionPool, Treasury, RiskRegistry, OracleAdapter, SettlementManager)
2. Agent record assessment ke RiskRegistry
3. Setup pool: PredictionPool + Treasury linked
4. Trader A buys YES (100 ETH), Trader B buys NO (100 ETH)
5. OracleAdapter report liquidity pull → true
6. SettlementManager execute settlement → YES wins
7. Trader A claims payout → receives ~200 ETH (minus fee)
8. Verify: payout correct, events emitted, state updated

### Scenario 2: Happy Path — Token Aman

1. Same setup as above
2. OracleAdapter report → false (no liquidity pull)
3. Settlement → NO wins
4. Trader B claims payout
5. Verify correct payout

### Scenario 3: Edge Cases

1. **Pool expired:** Try to buy position after deadline → revert `PoolExpired`
2. **Already claimed:** Try to claim twice → revert `AlreadyClaimed`
3. **Double settlement:** Try to settle resolved pool → revert
4. **Not oracle:** Non-oracle tries to settle → revert
5. **No positions:** Pool with 0 positions settles → no payout (0/0 = 0)

### Fuzz Test

```solidity
function testFuzz_BuyAndSettle(uint256 yesAmount, uint256 noAmount) public {
  vm.assume(yesAmount > 0.01 ether && yesAmount < 1000 ether);
  vm.assume(noAmount > 0.01 ether && noAmount < 1000 ether);
  // ... setup, buy, settle, claim, verify proportional payout
}
```

### Files to Create

| File | Path |
|------|------|
| Integration test | `contracts/test/Integration.t.sol` |

### Acceptance Criteria

- [ ] All scenarios pass
- [ ] Fuzz test passes (1000+ runs)
- [ ] Edge cases all covered
- [ ] `forge test` passes with no warnings
- [ ] `forge coverage` shows >90% coverage (if available)
