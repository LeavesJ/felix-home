### 2026-10-01: a table check that cannot fail because a final filter hides its status is refused, by one classifier every runner and schema-check share

Stacked on #375. The engine changes are:
- `lib/final-filter.sh`, `lib/final-filter-lex.sh` and `lib/final-filter-stages.sh`, which are new;
- the four table runners: `lib/commission.sh`, `lib/obligations.sh`, `lib/setup.sh` and `lib/maintenance.sh`;
- `felix` (setup and maintenance output);
- `bin/schema-check`;
- the commissioning template's comment;
- `tests/run`.

**Defect closed.** Every table runner evaluates a row without pipefail, so `npm test 2>&1 | tail -20` read done, or SATISFIED, when the tests failed. Now the command whose status a row returns is parsed as bash reads it. A row is refused when no path through its check can end in failure and at least one path ends in a final filter's success. The final filter is a last stage that succeeds whatever it is fed, on macOS and GNU alike.

**How a refusal surfaces, per table:**
- A commissioning check is malformed, so it fails the gate and blocks merge.
- An obligation's evidence is malformed, so it blocks merge.
- A setup check is never run, and its step reads todo.
- A maintenance event check is never run, and its task reads due with `refused` as the reason.
- schema-check refuses all four tables at the pull request that writes the row.
- The `when` and `applies` columns, probes and qualification are not judged. An unfailable command there only asks more.

**The rule was changed in the open.** The blind contract refused when *some* path ended in a filter. Precision review showed that refusing real checks whose guard can fail, such as `cd dir && npm test | tail` and `command -v jq && jq --version | cut …`. Three blind assertions and six more were amended, and each refused one keeps a refused partner. The six are tac, column and xargs, which were measured failing on macOS. Both commits say why.

**What was checked:**
- 1,332 real, worktree and historical judged tables: none refused.
- Commission and obligation row reads: byte-identical to origin/main on twelve projects.
- Differential fuzzing under /bin/bash 3.2.
- Two adversarial review rounds and a verification pass.

**Handed on, not done here:**
- No `risk.tsv` row guards `lib/final-filter*.sh`, so loosening the classifier does not fire the verifier. Adding one is a project-table edit that moves the policy hash, so it is left to the founder.
- gawk and mawk are not installed on the founder's machine. The awk was written to their known differences, and CI is the first run through GNU awk.

**Traps for whoever touches it:**
- The awk lives in single-quoted shell strings, so write `\047`, never a literal `'`.
- The Fact-Forcing Gate trips on `--delete` and `rm -rf` even inside heredocs.
- The tool shell is zsh, so `$list` does not word-split: use `${=list}` or `bash <<'EOF'`.
- bash 3.2 rejects `! !`, `&>>` and `|&`, and reads `{fd}>` as a word.
- An exit in a `for` or `case` returns the status of the expansion in its words.
