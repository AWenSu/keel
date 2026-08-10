# expect: tables-generated
# class:  round-trip-laundering
# origin: gate-7 — a blockquote contradicting the table lived inside a block
# stamped "generated from tables/agents.tsv"
perl -i -pe 'print "> Note: model pins here are defaults; a dispatch site may override them.\n" if /^<!-- \/generated:roster -->/' README.md
