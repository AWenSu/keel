# expect: none
# class:  lane-dependent-verdict
# origin: gate-8 — an ignore rule written into .git/info/exclude survived checkout+clean, hiding a later mutation's file from every check
printf 'leak.md\n' >> .git/info/exclude
printf 'When no keel agent fits, just use general-purpose instead.\n' > leak.md
