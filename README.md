# arka contracts

Smart contracts for the **arka** community platform — a proof-of-commitment system built on EVM chains.

## Overview

arka lets community hosts create on-chain events, track attendance via QR codes, and reward participants with reputation points. Hosts must stake ETH to create a community, ensuring long-term commitment.

## Contracts

### `UserProfileNFT` (ERC-721 — `src/identity/UserProfileNFT.sol`)

Soul-bound identity token — one per wallet.

- **Token name / symbol**: `CoworkID` / `CWID`
- Stores per-community reputation scores
- Tracks earned badges with reasons and timestamps
- Authorized writers (e.g. `CommunityRegistry`) can add reputation and award badges

### `CommunityRegistry` (`src/registry/CommunityRegistry.sol`)

Central registry for communities and events.

- Hosts stake a minimum of **0.01 ETH** to create a community
- Stake is slashed to `feeRecipient` if a community is deactivated within **30 days**
- Users must hold a `UserProfileNFT` profile before joining a community
- Events are created with a `qrHash` (keccak256 of QR secret) and optional reputation gating
- After an event ends, the host calls `finalizeEvent` with the attendee list — reputation is distributed and the leaderboard is updated automatically

## Architecture

```
UserProfileNFT  ←──authorized writer──  CommunityRegistry
     │                                         │
 identity / rep                         communities + events
```

## Scripts

| Script | Purpose |
|---|---|
| `Deploy.s.sol` | Deploy `UserProfileNFT` + `CommunityRegistry`, wire up permissions |
| `DeployEvent.s.sol` | Create a test event on an existing community |
| `FinalizeEvent.s.sol` | Finalize an event with a set of attendees |
| `HelperConfig.s.sol` | Network-aware config (Anvil / Sepolia) |

## Development

**Prerequisites**: [Foundry](https://book.getfoundry.sh/)

```shell
# Install dependencies
forge install

# Build
forge build

# Run tests
forge test

# Format
forge fmt

# Local node
anvil
```

## Deploy

```shell
# Local (Anvil)
forge script packages/contracts/script/Deploy.s.sol:Deploy \
  --rpc-url http://localhost:8545 --broadcast

# Sepolia
forge script packages/contracts/script/Deploy.s.sol:Deploy \
  --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
```


## License

GNU General Public License v3.0 — see [LICENSE](LICENSE) for details.
