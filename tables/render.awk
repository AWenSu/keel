# render.awk — emit one document with one generated block rewritten
#
# stdin: <agent-name>\t<model>   (pins read from agents/*.md frontmatter)
# -v TABLE=roster|gates|routes  DOCKEY=workflow|readme_en|readme_zh
# -v TSV=tables/<file>.tsv
#
# Every cell inside the markers comes from the tsv or from an agent's
# frontmatter. The first version read the prose cells back out of the document
# and re-emitted them, joining them to the source rows by POSITION — so
# inserting a route in the middle of routes.tsv re-paired five triggers with
# the wrong from/to, wrote that into all three documents, and `--check`
# certified the result as up to date. The block carried a provenance stamp
# wider than what the generator actually derived.
#
# The objection to putting prose in a tsv was that it makes the text harder to
# write. It does not: every cell of a markdown table is a single line already.
# That aesthetic call cost correctness, so it is reversed.

BEGIN {
  FS = "\t"
  while ((getline line < "/dev/stdin") > 0) {
    split(line, m, "\t"); MODEL[m[1]] = m[2]
  }

  hdr = 0
  while ((getline line < TSV) > 0) {
    if (line ~ /^#/) {
      sub(/^# */, "", line); NCOL = split(line, H, "\t"); hdr = 1; continue
    }
    if (line == "") continue
    NROW++
    if (split(line, F, "\t") != NCOL) {
      printf "FATAL: %s row %d has %d columns, header declares %d\n", \
        TSV, NROW, split(line, F, "\t"), NCOL > "/dev/stderr"
      exit 2
    }
    for (i = 1; i <= NCOL; i++) C[NROW, H[i]] = F[i]
  }
  if (!hdr || NROW == 0) { print "FATAL: could not read " TSV > "/dev/stderr"; exit 2 }

  OPEN  = "<!-- generated:" TABLE " "
  CLOSE = "<!-- /generated:" TABLE " -->"
}

!inblock {
  print
  if (index($0, OPEN) == 1) { inblock = 1; nold = 0; seen_open = 1 }
  next
}

inblock && index($0, CLOSE) != 1 {
  if ($0 ~ /^\|/) { nold++; OLD[nold] = $0 }
  else EXTRA[++nextra] = $0
  next
}

inblock && index($0, CLOSE) == 1 {
  # header and separator stay with the document: the READMEs carry a Tools
  # column the router's table does not, and the Chinese headings are Chinese
  print OLD[1]; print OLD[2]
  ncell = split(OLD[1], HC, "|") - 2

  for (i = 1; i <= NROW; i++) {
    if (TABLE == "roster") {
      name  = C[i, "name"]
      model = MODEL[name]; if (model == "") model = "—"
      # the READMEs bold opus so the expensive tier is visible at a glance;
      # a display convention, so it lives here and not in the data
      shown = (DOCKEY != "workflow" && model == "opus") ? "**" model "**" : model
      line = "| `" name "` | " C[i, "stage_" (DOCKEY == "readme_zh" ? "zh" : "en")] \
             " | " C[i, "role_" DOCKEY] " | " shown
      if (ncell >= 5) line = line " | " C[i, "tools_" DOCKEY]
      print line " |"
    } else if (TABLE == "gates") {
      print "| " emph(C[i, "id"]) " | " C[i, "where_" DOCKEY] " | " C[i, "what_" DOCKEY] " |"
    } else {
      print "| " C[i, "trigger_" DOCKEY] " | " C[i, "from_" DOCKEY] " | " C[i, "to_" DOCKEY] " |"
    }
  }
  for (i = 1; i <= nextra; i++) print EXTRA[i]
  print
  inblock = 0
  next
}

{ print }

END {
  # A block that was never found is a document passed through byte for byte,
  # which `cmp` then reports as up to date. One space in front of a marker used
  # to disable a whole table silently.
  if (!seen_open) { printf "FATAL: no <!-- generated:%s --> marker found\n", TABLE > "/dev/stderr"; exit 3 }
  if (inblock)    { printf "FATAL: <!-- generated:%s --> never closed\n", TABLE > "/dev/stderr"; exit 3 }
}

function emph(s) {
  if (DOCKEY == "workflow") return s
  if (TABLE == "gates") return "**" s "**"
  return s
}
