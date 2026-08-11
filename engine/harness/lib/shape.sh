# Execution shape: what can run in parallel, and what must not.
#
# This was decided by taste every time, which is another way of saying it held
# on one machine, for one person, and nowhere else. The dispatch rule everyone
# quotes — parallelise only genuinely separable workstreams, keep coupled
# changes under one lead context — lived in a document. A document is not a
# mechanism, so every session re-derived it from whoever was driving.
#
# Half of it is mechanical. Two units that write the same file cannot be worked
# in parallel: one overwrites the other, or they invent conflicting assumptions
# about a file neither owns. That half is computable, it is a **refusal**, and a
# refusal is the shape Felix is good at.
#
# The other half is not. Units touching disjoint files may still be coupled
# through an interface — a caller and the signature it consumes share no file at
# all. So disjointness is necessary and never sufficient, and this file is
# careful to say "these cannot fan out" with authority and "these may" without
# pretending it knows.
#
# The input is a plan written to the format writing-plans mandates, where every
# task declares the files it creates, modifies and tests. That block was already
# required for the benefit of whoever implements the task; it happens to be a
# dependency graph nobody was reading.

# task <TAB> path, one per line.
#
# A path may carry a line range (`file.py:120-140`) because the plan format
# encourages pointing at a region. The range is part of the address, not part of
# the file, and leaving it on would make two tasks editing the same file at
# different lines look independent — which is exactly the case that corrupts.
felix_shape_units() {
  local plan="$1"
  [ -f "$plan" ] || return 0
  awk '
    /^###[[:space:]]+Task[[:space:]]+/ {
      t = $3; sub(/:$/, "", t); task = t; next
    }
    /^-[[:space:]]+(Create|Modify|Test):[[:space:]]/ {
      if (task == "") next
      if (match($0, /`[^`]+`/)) {
        f = substr($0, RSTART + 1, RLENGTH - 2)
        sub(/:[0-9].*$/, "", f)
        if (f != "") print task "\t" f
      }
    }
  ' "$plan" | LC_ALL=C sort -u
}

# Connected components: comma-separated task lists, one group per line.
#
# Tasks that share a file are merged, transitively — if 1 and 2 share a lib and
# 2 and 3 share a test, all three are one unit of work even though 1 and 3 touch
# nothing in common. Merging only the direct pairs would report a group as
# separable while an edit travelled through the middle of it.
felix_shape_groups() {
  local plan="$1"
  [ -f "$plan" ] || return 0
  felix_shape_units "$plan" | awk '
    { file[$2] = file[$2] " " $1; tasks[$1] = 1 }
    END {
      # Start with every task in its own group, then union any two that appear
      # against the same file. Plans are small enough that repeating until
      # nothing changes is cheaper than carrying a union-find.
      for (t in tasks) parent[t] = t
      changed = 1
      while (changed) {
        changed = 0
        for (f in file) {
          n = split(file[f], members, " ")
          first = ""
          for (i = 1; i <= n; i++) {
            if (members[i] == "") continue
            r = members[i]
            while (parent[r] != r) r = parent[r]
            if (first == "") { first = r; continue }
            if (r != first) { parent[r] = first; changed = 1 }
          }
        }
      }
      for (t in tasks) {
        r = t
        while (parent[r] != r) r = parent[r]
        group[r] = (r in group) ? group[r] "," t : t
      }
      for (g in group) {
        n = split(group[g], m, ",")
        for (i = 1; i <= n; i++)
          for (j = i + 1; j <= n; j++)
            if (m[j] < m[i]) { tmp = m[i]; m[i] = m[j]; m[j] = tmp }
        out = m[1]
        for (i = 2; i <= n; i++) out = out "," m[i]
        print out
      }
    }
  ' | LC_ALL=C sort
}
