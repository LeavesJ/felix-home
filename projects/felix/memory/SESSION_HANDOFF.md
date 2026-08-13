# Handoff

Regenerated 2026-08-12. Anything below is the state of the tree,
not a summary of intent.

## Where

- branch: `main`
- head: `6d36244 fix(next): a ranking test was asserting the machine again`
- tree: `/Users/a14808/Documents/Felix`

## Uncommitted

```
 M HANDOFF.md
 M projects/felix/memory/SESSION_HANDOFF.md
```

## Recent

```
6d36244 2026-08-12 fix(next): a ranking test was asserting the machine again
1ff7ce5 2026-08-12 feat(next): rank the backlog Felix already tracks, and find upkeep that could never fire
f415706 2026-08-12 docs(handoff): the compliance panel is built, and answered from rows not a parser
ec4e62b 2026-08-12 feat(monitor): the panel that says whether the delegation works
e8be473 2026-08-12 docs(handoff): concurrent sessions checked, reviewer isolation enforced
5675518 2026-08-12 feat(review): independence cannot be checked; isolation can, and it is the half that breaks
af06e98 2026-08-12 fix(ledger): a fallback key meant for dedup was carrying ledger data
827b8c4 2026-08-12 doctrine(invariant-2): the reviewed exception, named where the invariant lives
```

## Next

- verify: `gate.sh`
- what was in progress: Phase 1 complete; PR #4 open on Elenchus awaiting merge. Next is item 2 in HANDOFF.md: PreToolUse binds Bash only, and the ledger now shows real sessions spending most calls on Read/Edit/Write that no deny rule can see.
