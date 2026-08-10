# expect: readme-roster
# class:  declared-not-wired
# origin: gate-4
perl -i -ne 'print unless /^\| `keel-plan-skeptic-critical` \|/' README.md
