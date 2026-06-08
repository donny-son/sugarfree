# Sugarfree in AI harnesses & build workflows

The `sugarfree` CLI is a plain **stdin → stdout filter** (see [`../cli/README.md`](../cli/README.md)):
deterministic, no network, exits `0` on success. That makes it easy to drop into
agent hooks, editor commands, and CI/build steps.

The CLI contract in one line:

```bash
cat input | sugarfree [flags] > output      # or: sugarfree FILE, or: sugarfree --clipboard
```

Exit codes: `0` success, `3` when run with `--check` and the content *would* change,
non-zero otherwise (bad flags, unreadable input).

## Claude Code hooks

See [`claude-code-settings.example.json`](claude-code-settings.example.json) for copy-paste
snippets. Two patterns:

- **`Stop` hook** — after each turn, run `sugarfree --clipboard --all` so whatever is on
  the clipboard pastes clean. Pair it with [`strip-clipboard.sh`](strip-clipboard.sh).
- **`UserPromptSubmit` hook** — pipe the submitted prompt through `sugarfree --all` to strip
  bold/italic/header noise before Claude reads it.

Point the `command` at an absolute path to the built binary (e.g. `/usr/local/bin/sugarfree`)
or to `strip-clipboard.sh`.

## Generic agent / harness hook

Any harness that can shell out can call the filter. Strip emphasis from a model's
markdown output before handing it to a plain-text sink:

```bash
agent --print | sugarfree --all
```

Or normalize tables into structured lists for downstream parsing:

```bash
agent --print | sugarfree --none --tables --table-format yaml
```

## Build / CI workflows

Use `--check` to **gate** a build on whether tracked content still carries sugar
(exit `3` = would change):

```bash
# Fail the job if any committed Markdown still has emphasis markers.
for f in $(git ls-files '*.md'); do
  sugarfree --check "$f" && continue
  echo "::error file=$f::contains formatting sugar — run 'sugarfree --all' on it"
  fail=1
done
[ -z "${fail:-}" ]
```

Or normalize in place as a pre-commit step:

```bash
tmp=$(mktemp); sugarfree --all "$file" > "$tmp" && mv "$tmp" "$file"
```

> The CLI never touches the network and is fully deterministic, so it's safe to run in
> sandboxed CI and agent environments.
