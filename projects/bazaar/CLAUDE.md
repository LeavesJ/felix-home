# bazaar

Governed by Felix. This file is the project constitution: what is true
about the Black Box Bazaar and nothing else.

The Black Box Bazaar is a claim-first market for counterexamples to claims
about a pinned AI model, on Base Sepolia. A buyer escrows bounties for
refutations of a claim it wrote down; sellers commit a hash, reveal the
counterexample encrypted to the buyer, and are paid when the buyer confirms,
an arbiter upholds them, or the buyer stays silent past the window. Silence
pays the seller and is recorded as unadjudicated, never as confirmed. That
rule is the product: silence is not evidence.

## Verification

Run the gate before claiming anything is done.

```bash
felix gate
```

It runs the Foundry suite, the agents' unit tests, refuses a tracked `.env`
or a stray 64-hex key, and checks that the exported ABI beside the agents and
the page matches the compiled contract. After any change to `src/`, run
`scripts/export-abi.sh <address> <chainId> <block>` or the abi check fails.

## Commands

```bash
export PATH="$HOME/.foundry/bin:$PATH"
forge test                                   # 39 contract tests
(cd agents && npm test)                      # agent unit tests, incl. the cross-seam vector
anvil --silent --port 8545 --block-time 1 &  # local chain; roles use anvil accounts 0-6
ARBITER_ADDRESS=0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc forge script script/Deploy.s.sol \
  --rpc-url http://127.0.0.1:8545 --private-key <anvil account 0 key> --broadcast
scripts/export-abi.sh <address> <chainId> <deployedBlock>   # agents/src/abi.json, docs/abi.json, docs/deployment.json
(cd agents && MARKET_ADDRESS=<address> CHAIN=anvil npm run -s buyer -- post)
demo/scenes.sh                               # the demo scenes against whatever .env points at
(cd demo && node record.mjs <page url>) && demo/cut.sh   # record, then compress the waits
```

Windows for a demo deploy: `REVEAL_WINDOW ADJUDICATION_WINDOW DISCLOSURE_WINDOW
ARBITRATION_WINDOW` in seconds (default 90), `BOND_BPS` (default 2000).

## Environment

`.env` at the repository root, never tracked: `ANTHROPIC_API_KEY`, `CHAIN`
(`base-sepolia` or unset for anvil), `DEPLOYER_KEY`, `DEPLOYER_ADDRESS`,
`BUYER_KEY`, `SELLER_KEY`, `ROGUE_KEY`, `NEWCOMER_KEY`, `QUIET_KEY`, `ARBITER_KEY`,
`ARBITER_ADDRESS`, `MARKET_ADDRESS`, `POLL_MS`. `agents/src/wallets.ts gen`
appends fresh role keys; `fund` sends each role test ETH from the deployer.

## Architecture

- `src/RefutationMarket.sol` is the whole on-chain surface: claims, sales,
  escrow, bonds, windows, reputation counters. No language model touches it.
  `test/RefutationMarket.t.sol` covers every transition and refusal.
- `agents/src/` are the participants: `buyer.ts`, `seller.ts`, `arbiter.ts`,
  `sweep.ts`, over shared `chain.ts` (viem), `crypto.ts` (x25519 envelopes and
  the commitment hash), `model.ts` (the pinned model and the reply
  classifier), `config.ts` (the one supported specification, role keys).
  Node 26 runs the `.ts` files natively; there is no build step.
- `docs/` is the static page served by GitHub Pages and reads chain state and
  events from a public RPC. `docs/abi.json` and `docs/deployment.json` are
  written by `scripts/export-abi.sh`.
- `demo/` is the recording: `scenes.sh` drives the participants and writes
  captions, `record.mjs` records the page with Playwright, `cut.sh`
  compresses the waits. Nothing under `demo/out` or `demo/logs` is tracked.
- `docs/superpowers/specs/` holds the design and its amendments after
  external review; `docs/superpowers/plans/` the implementation plan.

## Non-obvious patterns

- **A Foundry prank is spent by the next external call.** `vm.prank(x);
  m.commit{value: m.bondFor(id)}(...)` sends the prank to `bondFor`. Read
  everything external before pranking. Twenty-two tests failed this way once.
- **Windows are judged by `block.timestamp`, never wall-clock.** Anything that
  decides whether a window has passed reads the chain clock
  (`getBlock().timestamp`); on anvil the clock is warped with
  `evm_increaseTime`, so a wall-clock sweep silently does nothing.
- **`cast` and `forge` load the repository's `.env` on their own.** Once `.env`
  carries `CHAIN=base-sepolia`, any `cast call` run from the repo root without an
  explicit chain sends that chain id to whatever RPC it is pointed at, and anvil
  answers "invalid chain id for signer". Export `CHAIN=anvil` in the shell for local
  work, or run cast from outside the repo.
- **Shell environment wins over `--env-file`.** The npm scripts pass
  `--env-file=../.env`; exporting `MARKET_ADDRESS` and `CHAIN` in the shell
  overrides the file, which is how anvil runs coexist with a testnet `.env`.
- **The commitment is `keccak256(abi.encode(claimId, plaintext, salt))`** in
  that order on both sides of the seam, and one fixed vector is asserted in
  both the Solidity and the TypeScript suites.
- **Record on a fresh anvil.** Every `evm_increaseTime` leaves the chain clock ahead of the wall clock and the page shows block times, so a recording on a reused anvil dates events in the future; restart anvil and redeploy before recording.
- **Delivery is checked by the arbiter, not the chain.** The seller discloses
  its ephemeral secret and the arbiter rebuilds the ciphertext against the
  buyer's key before it runs the model. Say so wherever the mechanism is
  described.
- **`node --test` on Node 26 needs a glob**, not a directory: the test script
  is `node --test 'test/*.test.ts'`.
- **Felix's deny rule keys on command tokens.** A heredoc whose text puts
  `--force` near `push` is refused whatever it is writing; large documents go
  through the file tool.

## Invariants

Empty on purpose, and not for long.

These are the things no linter can catch, and they are earned rather
than invented. The gate records what it catches in `memory/mistakes.log`.
Anything it catches twice shows up in `felix promote`. A mistake that
keeps happening becomes a lesson; a lesson that keeps being violated
has outgrown the lessons file and belongs here, where the gate can see
it.

## Risk

Tiers live in `risk.tsv`, evidence requirements in `evidence.tsv`, both
beside this file. `src/` and `test/` are red: the contract moves money and a
mistake there is a mistake for every participant. `agents/` is yellow.
Documentation and the page are green. `felix classify` and `felix evidence`
read them, and nothing red is ever touched unattended.
