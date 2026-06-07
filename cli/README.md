# sugarfree CLI

A cross-platform command-line version of Sugarfree. It strips formatting "sugar"
(bold, italic, underline, strikethrough, headers) from text, HTML, or RTF, and can
optionally convert tables into YAML/TOML lists — using the exact same
[`SugarCore`](../Sources/SugarCore) logic as the macOS menu-bar app, so behavior
never drifts between the two.

It's a plain **stdin → stdout filter**: deterministic, no network. Ideal for
shell pipelines, [AI-harness hooks](../hooks/README.md), and build steps.

## Install

**From source** (Swift 5.9+ on macOS, Linux, or Windows):

```bash
swift build -c release --product sugarfree
# binary at .build/release/sugarfree  (.exe on Windows)
```

**From a release:** download the archive for your platform from the
[Releases page](https://github.com/donny-son/sugarfree/releases) (built by
`.github/workflows/release.yml`), verify the `.sha256`, unpack, and put `sugarfree`
on your `PATH`.

| Platform | Asset |
|---|---|
| macOS (Apple Silicon + Intel, universal) | `sugarfree-<ver>-macos-universal.tar.gz` |
| Linux x86_64 | `sugarfree-<ver>-linux-x86_64.tar.gz` |
| Linux arm64 | `sugarfree-<ver>-linux-arm64.tar.gz` |
| Windows x86_64 | `sugarfree-<ver>-windows-x86_64.zip` |

## Usage

```
sugarfree [FILE] [flags]
```

Reads `FILE` (or stdin) and writes the cleaned result to stdout. **Bold and italic
are stripped by default**, matching the app.

### Selecting sugars

| Flag | Effect |
|---|---|
| `--bold` / `--no-bold` | toggle bold (default: on) |
| `--italic` / `--no-italic` | toggle italic (default: on) |
| `--underline` / `--no-underline` | toggle underline (HTML/RTF only) |
| `--strikethrough` / `--no-strikethrough` | toggle strikethrough |
| `--headers` / `--no-headers` | toggle headers |
| `--all` | strip every sugar |
| `--none` | strip nothing (useful with `--tables`) |

Per-sugar flags layer on top of `--all` / `--none` / the default, e.g.
`--all --no-headers` strips everything except headers.

### Input format

`--format auto|text|html|rtf` (default `auto`). Auto-detection sniffs an RTF
signature or HTML tags, otherwise treats the input as Markdown/plain text. RTF is
**macOS only** (it needs AppKit); on other platforms use `text`/`html`.

### Table transform

| Flag | Effect |
|---|---|
| `--tables` | convert Markdown & HTML tables into list items |
| `--table-format yaml\|toml` | output style (default `yaml`) |

### Other

| Flag | Effect |
|---|---|
| `--clipboard` | read from and write back to the system clipboard instead of stdio |
| `--check` | write nothing; exit `3` if the content would change, else `0` |
| `--version` | print the CLI version |

`--clipboard` is best-effort off macOS: it shells out to `wl-copy`/`xclip`/`xsel`
if present, and errors clearly if none is found.

## Examples

```bash
# Strip bold+italic from the clipboard text (macOS pbpaste/pbcopy shown):
pbpaste | sugarfree | pbcopy

# Strip every sugar from a Markdown file, in place:
sugarfree --all notes.md > notes.clean.md

# Leave emphasis, just flatten tables into YAML list items:
sugarfree --none --tables in.md

# Strip from HTML explicitly:
cat page.html | sugarfree --html

# Clean the system clipboard in place:
sugarfree --clipboard --all

# Gate a build: non-zero if the file still contains sugar.
sugarfree --check README.md
```
