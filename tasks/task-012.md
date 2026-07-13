# Task-012: Deployment Scripts + End-to-End Flow

**Prioritas:** P0
**Dependencies:** 001-006 (all contracts)
**Module:** contracts/script/

---

## Objective

Buat deployment script Foundry untuk deploy semua kontrak ke Base Sepolia, plus verification.

## Specification

Lihat `docs/architecture/deployment.md`.

### Deploy Script

```solidity
// contracts/script/DeployRugRadar.s.sol

contract DeployRugRadarScript is Script {
  function run() external {
    vm.startBroadcast(privateKey);

    Treasury treasury = new Treasury();
    RiskRegistry registry = new RiskRegistry();
    OracleAdapter oracle = new OracleAdapter();
    SettlementManager settlement = new SettlementManager(oracle);
    AttestationAdapter attestation = new AttestationAdapter(easAddress);

    // Set permissions
    registry.setAgent(agentAddress);
    oracle.setSettlementManager(address(settlement));

    vm.stopBroadcast();
  }
}
```

### Deploy PredictionPool Script

```solidity
// contracts/script/DeployPredictionPool.s.sol

contract DeployPredictionPoolScript is Script {
  function run(address tokenAddress) external {
    vm.startBroadcast(privateKey);
    PredictionPool pool = new PredictionPool(tokenAddress, treasury, settlement);
    vm.stopBroadcast();
  }
}
```

### Verification

```bash
forge verify-contract --chain-id 84532 \
  --constructor-args $(cast abi-encode "constructor(address,address)" $treasury $settlement) \
  src/core/PredictionPool.sol:PredictionPool \
  $CONTRACT_ADDRESS
```

### End-to-End Demo Flow

Buat script demo yang bisa di-run di anvil:

```typescript
// scripts/demo.ts
// 1. Deploy all contracts ke anvil
// 2. Simulate token detection
// 3. Run assessment
// 4. Open pool
// 5. Buy positions (YES + NO)
// 6. Oracle reports liquidity pull
// 7. Settlement
// 8. Claim
// 9. Verify all states
```

### Files to Create

| File | Path |
|------|------|
| Deploy script | `contracts/script/DeployRugRadar.s.sol` |
| Deploy pool | `contracts/script/DeployPredictionPool.s.sol` |
| Demo script | `scripts/demo.ts` |
| Makefile | `Makefile` (common commands) |

### Common Commands (Makefile)

```makefile
deploy-sepolia:
  forge script script/DeployRugRadar.s.sol --rpc-url sepolia --broadcast

deploy-anvil:
  anvil &; forge script script/DeployRugRadar.s.sol --rpc-url localhost:8545 --broadcast

verify:
  forge verify-contract ...
```

### Acceptance Criteria

- [ ] `forge script DeployRugRadar` runs without error on anvil
- [ ] All contracts deployed and linked correctly
- [ ] Demo script runs end-to-end without error
- [ ] Contract verified on Basescan
