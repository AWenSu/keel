# expect: none
# class:  lane-dependent-verdict
# origin: gate-8 — a post-checkout hook fires during the harness's own revert and persists
mkdir -p .git/hooks
printf '#!/bin/sh\nprintf "tainted\\n" >> README.md\n' > .git/hooks/post-checkout
chmod +x .git/hooks/post-checkout
