# Sentence-level judgement of "is this a prohibition or an endorsement?"
# A window regex cannot do this: with commas allowed, "When no keel agent
# fits, just dispatch a general-purpose agent" reads as a prohibition; with
# commas forbidden, "Do not dispatch, under any circumstances, a
# general-purpose agent" reads as an endorsement. Both were live defects.
# The negation has to govern either the term or the verb that takes it.
function judge(sent,   pre, post, p) {
  p = index(tolower(sent), "general-purpose")
  if (p == 0) return 1
  pre  = tolower(substr(sent, 1, p - 1))
  post = tolower(substr(sent, p + 15, 80))
  # (a) negation immediately governing the term: "never `general-purpose`"
  if (pre ~ /(never|not|no|avoid|forbidden|絕不|不要)( +(the|a|an|any|its|this|that|generic|plain|bare|silent|ambient|通用的|內建的))* *$/) return 1
  # (b) negation governing the verb that takes it: "do not dispatch",
  #     "never silently fall back to"
  if (pre ~ /(never|not|no longer|no|avoid|forbidden|絕不|不要|不再)[,;]? *([a-z]+ly +)?(dispatch|dispatches|dispatching|use|uses|using|fall|falls|falling|route|routes|pass|passes|派工|派給|丟給|交給|降級)/) return 1
  # (c) the consequence stated after the term: "... is a bug", "... is never
  #     acceptable", "silently falls back to ... : no pinned model"
  if (post ~ /is a bug|forbidden|never acceptable|not acceptable|no pinned|沒釘死|沒鎖|是 ?bug/) return 1
  # (d) descriptive prose about the degradation, not a recommendation
  if (pre ~ /(falls? back|silently|degrad|降級|偷偷|不再|instead of|rather than)[^.]{0,40}$/) return 1
  # (e) a sentence about the failure mode, not a recommendation of it:
  #     "a general-purpose dispatch can still slip through"
  if (tolower(sent) ~ /can still|still slip|slip through|risk of|溜過|漏掉/) return 1
  return 0
}
{ buf = buf " " $0 }
END {
  gsub(/[*`]/, "", buf)
  n = split(buf, S, /[.。!?！？]+/)
  for (i = 1; i <= n; i++) {
    if (tolower(S[i]) !~ /general-purpose/) continue
    if (judge(S[i])) { good++; continue }
    s = S[i]; sub(/^ +/, "", s)
    printf "%s: %s\n", F, substr(s, 1, 90)
  }
  if (COUNT) print "PROHIBITIONS=" good+0
}
