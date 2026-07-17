.PHONY: build test test-all test-pp test-tr fmt check clean coverage

build:
	cd contracts && forge build

test: test-all
test-all:
	cd contracts && forge test

test-pp:
	cd contracts && forge test --match-path test/PredictionPool.t.sol -vvv

test-tr:
	cd contracts && forge test --match-path test/Treasury.t.sol -vvv

fmt:
	cd contracts && forge fmt

check:
	cd contracts && forge fmt --check

clean:
	cd contracts && forge clean

coverage:
	cd contracts && forge coverage --report lcov
