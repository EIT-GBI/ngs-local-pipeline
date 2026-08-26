Fake tool executables for `-stub-run` only.

Every module declares `eval(...)` version outputs, and Nextflow runs those
commands even when a process's `stub:` block replaces its script — if the
command is missing, the task fails with "Unable to evaluate output" (exit 127).
That is documented behaviour, not a bug: "if the command fails, the task will
also fail".

So a stub run needs the tools to *exist*, not to work. These scripts print a
plausible version string in the exact shape each module's `eval` command parses,
and nothing else.

They are on PATH only under `-profile stub` (see `nextflow.config`), so a real
run can never pick them up and shadow the containerised tools.
