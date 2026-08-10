# render.awk — emit one document with one generated block rewritten
#
# stdin: <agent-name>\t<model>   (pins read from agents/*.md frontmatter)
# -v TABLE=roster|gates|routes  DOCKEY=workflow|readme_en|readme_zh
# -v TSV=tables/<file>.tsv      DOC=<path to the document>
#
# Keys: roster rows key on the agent name, gates on the gate id, routes on
# position — a route's trigger text differs in all three documents, so there is
# no shared key to match on, and position is what the tsv defines.

BEGIN {
  FS = "\t"
  while ((getline line < "/dev/stdin") > 0) {
    split(line, m, "\t"); MODEL[m[1]] = m[2]
  }

  # tsv → NROW rows of columns C[i, header]
  hdr = 0
  while ((getline line < TSV) > 0) {
    if (line ~ /^#/) {
      sub(/^# */, "", line); split(line, H, "\t"); NCOL = 0
      for (i in H) NCOL++
      hdr = 1; continue
    }
    if (line == "") continue
    NROW++; split(line, F, "\t")
    for (i = 1; i <= NCOL; i++) { name = H[i]; sub(/ .*$/, "", name); C[NROW, name] = F[i] }
  }
  if (!hdr || NROW == 0) { print "FATAL: could not read " TSV > "/dev/stderr"; exit 2 }

  OPEN  = "<!-- generated:" TABLE " "
  CLOSE = "<!-- /generated:" TABLE " -->"
}

# pass through until the block opens
!inblock {
  print
  if (index($0, OPEN) == 1) { inblock = 1; nold = 0 }
  next
}

# inside the block: collect the old rows, then emit the new table at the close
inblock && index($0, CLOSE) != 1 {
  if ($0 ~ /^\|/) { nold++; OLD[nold] = $0 }
  else EXTRA[++nextra] = $0     # a stray non-table line inside the block
  next
}

inblock && index($0, CLOSE) == 1 {
  # header and separator come from the document itself: the columns differ per
  # document (the READMEs carry a Tools column the router's table does not)
  print OLD[1]; print OLD[2]
  ncell = split(OLD[1], HC, "|") - 2

  # old prose, keyed the way this table keys
  for (r = 3; r <= nold; r++) {
    n = split(OLD[r], cells, "|")
    k = cells[2]; gsub(/[ *`]/, "", k)
    if (TABLE == "routes") PROSE[r - 2] = OLD[r]
    else                   BYKEY[k] = OLD[r]
  }

  for (i = 1; i <= NROW; i++) {
    if (TABLE == "roster") {
      name = C[i, "name"]
      src  = BYKEY[name]
      role = cell(src, 3); tools = cell(src, 5)
      model = MODEL[name]; if (model == "") model = "—"
      stage = C[i, "stage_" (DOCKEY == "readme_zh" ? "zh" : "en")]
      # the READMEs bold opus to make the expensive tier visible at a glance;
      # that is a display convention, so it lives here and not in the data
      shown = (DOCKEY != "workflow" && model == "opus") ? "**" model "**" : model
      line = "| `" name "` | " stage \
             " | " (role == "" ? "TODO: describe this agent" : role) " | " shown
      if (ncell >= 5) line = line " | " (tools == "" ? "TODO: state the tool grant" : tools)
      print line " |"
    } else if (TABLE == "gates") {
      id   = C[i, "id"]
      src  = BYKEY[id]
      what = cell(src, 3)
      print "| " emph(id) " | " C[i, "where_" DOCKEY] " | " \
            (what == "" ? "TODO: state what this gate asks" : what) " |"
    } else {
      src = PROSE[i]
      trigger = cell(src, 1)
      print "| " (trigger == "" ? "TODO: state the trigger" : trigger) " | " \
            C[i, "from_" DOCKEY] " | " C[i, "to_" DOCKEY] " |"
    }
  }
  for (i = 1; i <= nextra; i++) print EXTRA[i]
  print
  inblock = 0
  next
}

{ print }

# cell(row, n): the nth data cell of a markdown row, trimmed
function cell(row, n,   parts, c) {
  if (row == "") return ""
  split(row, parts, "|")
  c = parts[n + 1]
  gsub(/^ +| +$/, "", c)
  return c
}

# the READMEs bold the key column; the router's tables do not
function emph(s) {
  if (DOCKEY == "workflow") return s
  if (TABLE == "gates") return "**" s "**"
  return s
}
