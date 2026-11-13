### 2026-11-12: the budget row reads GitHub's usage report (stuck-PR spec R13, 0.49.340)

**What this is.** A fix to the `budget` source row of `felix land --prs`, on branch `LeavesJ/nostalgic-keller-e94a07`. The row had read `unread` since 2026-10-13 and blamed the token's scope. On 2026-11-10 the founder added the `user` scope and it still read `unread`: GitHub has retired `users/<owner>/settings/billing/actions` (HTTP 410). The spec is `audits/2026-10-01-report-v5-review/specs/stuck-pr/amendment-r13-budget-usage-report.md` in the memory root; it replaces section 4.4 and R2 of spec v2 for this row.

**What changed.**
- **`lib/pr-status-gh.sh`.** `_ps_budget` makes one `gh api` GET of `users/<owner>/settings/billing/usage` for the clock's year and month in UTC, and of `orgs/<owner>/...` only after a 404. It sums the Actions items dated in that month: minutes over every SKU in minutes, net over all of them. The row says `<minutes> Actions minutes used in <YYYY-MM>, net $<amount>`, and no quota: the 39 items read from the two answers measured hold no field for one.
- **Reasons.** A failed read gives gh's first error line and at most one clause: the scope gh itself names, a 410 as moved, or a 404 as what GitHub answers for an account that does not exist or whose billing the login may not read. "The token may lack the user scope" is gone.
- **What a report has to be.** An answer that ends early or has text after it, a `usageItems` that is not a list, and an Actions item with no date each leave the row `unread` and say which. An owner that is not an account name is not put into an address.
- **Tests.** Part 1340's billing block was rewritten blind from the amendment, in two passes, each red first: 35 assertions named `R13:`, 26 failing on main at 212830c4; then 20 more from the section amended after review, 12 failing on the first build (952bd6f8). All 55 pass here. The gh stubs of the other stuck-PR and lost-work fixtures serve the usage report. Two assertions of part 1310 follow the amendment (the address, and the net amount where "of the minutes included" was).
- **Review.** One review of the first build, by a reader given the spec and the diff: nothing blocking, two fixes taken (a truncated answer was summed and printed as read; the walk's cost tripled with each doubling of the answer), and the smaller gaps written into the spec as A3 to A7.

**Read on the founder's account, 2026-11-13 about 00:40Z and again about 00:54Z.** `5925 Actions minutes used in 2026-11, net $20.36`, across `felix-home` and `ReserveGrid-OS`. October's report: about 4,715 minutes, net $5.95 (read on 2026-11-10 by the session that asked for this fix).

**Open.**
- A token without the `user` scope was not tried on the usage report. gh's scope line was measured on two other GETs, and the report's `X-Accepted-OAuth-Scopes: user` header is what gh builds that line from.
- An organisation's report was not read: the login belongs to none. The `orgs/` path is a route GitHub documents, and that is what was measured.
- During the review, 15 GETs of `users/fixture/settings/billing/usage` reached GitHub under the founder's login, from a stub placed on a relative PATH. Each was a read, answered 404.
- Reading an 8,000-item answer took 2.85 s of CPU here; the page has no timeout of its own on gh or on the read.
- The reader follows no pages. The answers measured carried no `Link` header (17 and 22 items).
- The row states no quota and no warning level. Whether Felix should warn at some spend is not decided.

**Release.** 0.49.340 fails closed until the founder authorizes it by name (direction row 49).
