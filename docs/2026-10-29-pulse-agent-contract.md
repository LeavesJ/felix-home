# The pulse agent runs where macOS lets it start

Contract for one change to `felix pulse --install`: the launchd agent it writes,
`~/Library/LaunchAgents/felix.pulse.plist`. Adversarial tier (engine/harness).

## What happened

On 2026-10-29, the first day on the new Mac (macOS 27.0.1, Migration Assistant
from 26.7.1), the scheduled pulse could not start. launchd logged

    Service could not initialize: Unable to open stdout path
    (/Users/a14808/Documents/Felix/state/pulse.log.launchd.log),
    error 0x1 - Operation not permitted

and `launchctl print` reported `last exit code = 78: EX_CONFIG`, `job state =
spawn failed`. The program never ran, so nothing was written anywhere Felix reads,
and `verify-new-mac.sh` called it "loaded and has not run yet". `/bin/bash` and
`/usr/bin/env` both held Full Disk Access throughout.

Measured that evening, each time with the real agent in `~/Library/LaunchAgents`
(where launchd registers it as a background item) and a kickstart:

| ProgramArguments starts with | StandardOutPath | Result |
|---|---|---|
| the `felix` script | `<home>/state/pulse.log.launchd.log` | spawn failed, 78 |
| `/bin/bash`, then the script | `<home>/state/pulse.log.launchd.log` | spawn failed, 78 |
| the `felix` script | `~/Library/Logs/felix/pulse.launchd.log` | exit 0, backup pushed and verified |
| `/bin/bash`, then the script | `~/Library/Logs/felix/pulse.launchd.log` | exit 0, backup pushed and verified |

launchd opens the capture file itself, before the program starts, and macOS
refuses that open under `~/Documents` whatever the program is. Once the program
starts, its own reads and writes under the home succeed, because the shell that
runs it holds Full Disk Access (amendment A31 of the land-on-green contract). A
job started from a shell outside `~/Library/LaunchAgents` does not reproduce
this: it inherits the starting shell's grant, so such a probe says nothing.

Why the same plist ran daily on the old Mac is not known.

## What must hold

- **P1 The program.** `ProgramArguments` is exactly three strings: `/bin/bash`,
  the served engine's `felix` path (resolved as today), and `pulse`. This is A31's
  rule for the land job. It stops the agent from depending on whichever `bash`
  `/usr/bin/env` finds on launchd's PATH, and on `env` holding a grant of its own.
- **P2 The capture.** `StandardOutPath` and `StandardErrorPath` are the same
  file: `$HOME/Library/Logs/felix/pulse.launchd.log`. Neither may be inside the
  Felix home, and neither may be under `$HOME/Documents`.
- **P3 The directory.** launchd does not create a missing parent, and fails the
  spawn the same way. So the installer creates `$HOME/Library/Logs/felix` before
  it writes the plist. If it cannot, it says so, writes no plist, hands launchd
  nothing, and exits 1.
- **P4 What it says.** The install message still names the pulse's own log. It
  also names the capture file, so a person reading a failed run knows where
  launchd wrote.
- **P5 Unchanged.** The label, the 09:07 daily schedule, the served-engine
  resolution, `--uninstall` and the non-Darwin refusal stay as they are. So does
  the pulse's own log, `<home>/state/pulse.log`, which the running program writes
  under the shell's grant. Uninstall leaves the capture file in place, because a
  log is not a grant.

## Out of scope

- `felix status` already reports the agent's last exit (`exit-78`), and turning
  that into an alert is a separate change.
- An already-installed agent keeps its old plist until `felix pulse --install`
  runs again. On this Mac it was rewritten by hand to the P1-P3 form on
  2026-10-29.
