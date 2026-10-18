# The parallel runner (contract D6): _par_run hands every unit of $_sj_units to a
# process of its own and judges what they leave. This is a stand-in, so that the
# hand-over lines of the driver have something to call: it makes no assertion,
# says plainly that the runner is not built, and ends the run red. The runner
# replaces it. It defines functions and runs nothing when sourced.
_par_run() {
  printf '  FAIL  the parallel runner is not built: part 0007 holds a stand-in (contract D6)\n'
  exit 1
}
