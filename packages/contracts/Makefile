build:
	forge build
	./scripts/export-abi.sh

DOPPLER_PROJECT = arka
DOPPLER_CONFIG  = dev
DOPPLER         = doppler run --project $(DOPPLER_PROJECT) --config $(DOPPLER_CONFIG) --

CONTRACTS_DIR   = packages/contracts
APP_DIR         = packages/app

.PHONY: deploy-local deploy-arb-sepolia sync-abis dev

deploy-local:
	cd $(CONTRACTS_DIR) && $(DOPPLER) forge script script/Deploy.s.sol \
		--rpc-url http://127.0.0.1:8545 \
		--broadcast

deploy-arb-sepolia:
	cd $(CONTRACTS_DIR) && $(DOPPLER) forge script script/Deploy.s.sol \
		--rpc-url $$ARB_SEPOLIA_RPC_URL \
		--broadcast \
		--verify

sync-abis:
	cd $(CONTRACTS_DIR) && forge build
	cp $(CONTRACTS_DIR)/out/CommunityRegistry.sol/CommunityRegistry.json $(APP_DIR)/lib/abi/
	cp $(CONTRACTS_DIR)/out/UserProfileNFT.sol/UserProfileNFT.json $(APP_DIR)/lib/abi/
	@echo "ABIs synced"

dev:
	cd $(APP_DIR) && npm run dev
