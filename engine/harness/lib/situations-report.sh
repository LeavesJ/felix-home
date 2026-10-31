# felix situations, the report (slice 1 of the capability lane; contracts C8 to C11 of
# docs/2026-10-29-lane-slice-1-plan.md). Loaded by cmd_situations in felix, after lib/situations.sh. Definitions only.
#
# It prints one of three things, all from the evaluation the other two libraries make and none from a clock, a model or
# the network:
#
#   the human report   situations for <project>, how each side was read, the sections owed, blinded, retired, standing
#                      and residual in --change (standing and residual in --at), and the count line (C9)
#   --tsv              one line per class, then the residual lines, in an order that does not depend on the caller's
#                      locale (C8); slice 2 reads this form
#   --propose          after the count line, a drafted obligations row and the command that would admit it for each
#                      class that is ACTIVE and not yet admitted (C11); it writes nothing
#
# Not built in this file yet: the printers arrive with the evaluation, in the tasks that follow the command and its table.
