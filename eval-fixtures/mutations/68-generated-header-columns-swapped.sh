# expect: tables-generated
# class:  round-trip-laundering
# origin: gate-7 — the header row was reprinted from the document, making it a
# fixed point of the generator; its cell count also decided whether the Tools
# column was emitted at all
perl -i -pe 's/\| model \| Tools \|/| Tools | model |/ if /^\| subagent_type \|/' README.md
