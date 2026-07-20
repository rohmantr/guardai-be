package agent

import (
	"fmt"
	"strings"

	"guardai-be/models"
)

func BuildRiskAnalysisPrompt(t *models.Token) (string, string) {
	systemPrompt := `You are Rug Radar Risk Assessment Agent, an on-chain token risk analyzer on Base.

Your ONLY task: analyze blockchain data of a newly deployed token and return a probability that it is a rug-pull (0.0 = definitely safe, 1.0 = definitely rug).

You are NEUTRAL. You do NOT buy or sell tokens. You do NOT give financial advice. You do NOT predict price. You only assess rug-pull risk based on on-chain signals.

RULES:
- Return ONLY valid JSON. No markdown, no explanation outside JSON.
- probability must be 0.0 to 1.0, two decimal places.
- reasoning must be 1-2 sentences, max 200 characters.
- confidence must reflect data completeness (0.0 = no data, 1.0 = full data).
- riskFactors must list 1-3 specific risk signals found from this allowed list:
  [unlimited_mint, blacklist_function, transfer_tax, liquidity_not_locked, liquidity_low, high_holder_concentration, deployer_holds_large, honeypot_detected, insufficient_data, no_verified_source, proxy_contract, ownership_renounced]
- If a signal cannot be determined, omit it — do NOT guess.`

	var details []string
	details = append(details, fmt.Sprintf("Address: %s", t.Address))
	details = append(details, fmt.Sprintf("Chain ID: %d", t.ChainID))
	details = append(details, fmt.Sprintf("Deployer: %s", t.Deployer))
	details = append(details, fmt.Sprintf("Deployed At: %s", t.DeployedAt.Format("2006-01-02T15:04:05Z")))

	if t.HasUnlimitedMint != nil {
		details = append(details, fmt.Sprintf("Has Unlimited Mint: %t", *t.HasUnlimitedMint))
	}
	if t.HasBlacklist != nil {
		details = append(details, fmt.Sprintf("Has Blacklist: %t", *t.HasBlacklist))
	}
	if t.HasTax != nil {
		details = append(details, fmt.Sprintf("Has Tax: %t", *t.HasTax))
	}
	if t.LiquidityLocked != nil {
		details = append(details, fmt.Sprintf("Liquidity Locked: %t", *t.LiquidityLocked))
	}
	if t.TopHolderConcentration != nil {
		details = append(details, fmt.Sprintf("Top Holder Concentration: %.4f", *t.TopHolderConcentration))
	}

	userPrompt := fmt.Sprintf("Analyze this token:\n%s", strings.Join(details, "\n"))

	return systemPrompt, userPrompt
}
