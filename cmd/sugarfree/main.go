// Command sugarfree is a Unix filter that strips formatting "sugar" from text.
//
// It reads from stdin (or file arguments), strips the chosen sugars from the
// Markdown/plain-text (default) or HTML representation, optionally reshapes
// tables into list items, and writes the result to stdout. It mirrors the macOS
// menu-bar app's stripping (kept in parity by a shared golden test corpus).
//
// Built for LLM pipelines, shell workflows, and Claude Code hooks, e.g.:
//
//	llm "explain X" | sugarfree
//	pbpaste | sugarfree --all | pbcopy
//	sugarfree --tables yaml < report.md
package main

import (
	"fmt"
	"io"
	"os"
	"strings"

	"github.com/donny-son/sugarfree/internal/sugar"
)

// version mirrors the app's MARKETING_VERSION; bump both together.
const version = "1.2.0"

const helpText = `sugarfree — strip formatting sugar from text (stdin → stdout)

USAGE:
    sugarfree [OPTIONS] [FILE ...]

Reads from stdin when no FILE is given (use "-" for explicit stdin). With no
sugar flags it strips bold + italic — the same defaults as the menu-bar app.

SUGAR SELECTION:
    --all                  Strip every sugar (bold, italic, underline,
                           strikethrough, headers).
    --bold                 Strip bold (**x**, __x__, <strong>, <b>, font-weight).
    --italic               Strip italic (*x*, _x_, <em>, <i>, font-style).
    --underline            Strip underline (<u>, text-decoration; HTML only).
    --strikethrough        Strip strikethrough (~~x~~, <s>/<del>/<strike>).
    --headers              Strip ATX headers (# .. ###### …) and <h1>–<h6>.
    --strip <list>         Comma-separated set, e.g. --strip bold,headers.
    --no-<sugar>           Remove one sugar from the set (handy with --all),
                           e.g. --all --no-headers.

    Naming any --<sugar> / --strip flag replaces the bold+italic default with
    exactly the set you list. --no-<sugar> flags are applied last.

INPUT FORMAT:
    --html                 Treat input as HTML (default is Markdown/plain text).

TRANSFORMS (lossy, off by default):
    --tables <yaml|toml>   Convert Markdown/HTML tables into list items.

OTHER:
    -h, --help             Show this help.
    --version              Print the version.

EXAMPLES:
    llm "summarize" | sugarfree           # strip bold + italic
    pbpaste | sugarfree --all | pbcopy    # strip everything, back to clipboard
    sugarfree --strip headers,bold notes.md
    sugarfree --html < email.html
    sugarfree --tables toml < report.md`

func fail(format string, args ...any) {
	fmt.Fprintf(os.Stderr, "sugarfree: "+format+"\n", args...)
	fmt.Fprintln(os.Stderr, "Try 'sugarfree --help' for usage.")
	os.Exit(2)
}

func parseTableFormat(value string) sugar.Format {
	switch strings.ToLower(value) {
	case "yaml", "yml":
		return sugar.YAML
	case "toml":
		return sugar.TOML
	default:
		fail("unknown table format '%s' (expected yaml or toml)", value)
		return sugar.YAML // unreachable
	}
}

func parseSugar(name string) sugar.Sugar {
	switch strings.ToLower(name) {
	case "bold":
		return sugar.Bold
	case "italic":
		return sugar.Italic
	case "underline":
		return sugar.Underline
	case "strikethrough", "strike":
		return sugar.Strikethrough
	case "heading", "headings", "header", "headers":
		return sugar.Heading
	default:
		fail("unknown sugar '%s' (expected bold, italic, underline, strikethrough, headers)", name)
		return "" // unreachable
	}
}

func main() {
	explicit := sugar.NewSet() // sugars named via --<sugar> / --strip / --all
	explicitUsed := false      // did the user name any sugar explicitly?
	removals := sugar.NewSet() // sugars subtracted via --no-<sugar>
	asHTML := false
	var tableFormat *sugar.Format // nil = transform off
	var files []string
	sawDoubleDash := false

	addStripList := func(list string) {
		for _, name := range strings.Split(list, ",") {
			explicit.Add(parseSugar(strings.TrimSpace(name)))
		}
		explicitUsed = true
	}
	setTableFormat := func(value string) {
		f := parseTableFormat(value)
		tableFormat = &f
	}

	args := os.Args[1:]
	for i := 0; i < len(args); i++ {
		arg := args[i]

		if sawDoubleDash {
			files = append(files, arg)
			continue
		}

		switch arg {
		case "-h", "--help":
			fmt.Println(helpText)
			os.Exit(0)
		case "--version":
			fmt.Println(version)
			os.Exit(0)
		case "--":
			sawDoubleDash = true
		case "-":
			files = append(files, arg)
		case "--all":
			for _, s := range sugar.All {
				explicit.Add(s)
			}
			explicitUsed = true
		case "--bold", "--italic", "--underline", "--strikethrough", "--headers", "--heading":
			explicit.Add(parseSugar(strings.TrimPrefix(arg, "--")))
			explicitUsed = true
		case "--no-bold", "--no-italic", "--no-underline", "--no-strikethrough", "--no-headers", "--no-heading":
			removals.Add(parseSugar(strings.TrimPrefix(arg, "--no-")))
		case "--strip":
			if i+1 >= len(args) {
				fail("--strip requires a comma-separated list")
			}
			i++
			addStripList(args[i])
		case "--html":
			asHTML = true
		case "--tables":
			if i+1 >= len(args) {
				fail("--tables requires a format (yaml or toml)")
			}
			i++
			setTableFormat(args[i])
		default:
			switch {
			case strings.HasPrefix(arg, "--strip="):
				addStripList(strings.TrimPrefix(arg, "--strip="))
			case strings.HasPrefix(arg, "--tables="):
				setTableFormat(strings.TrimPrefix(arg, "--tables="))
			case strings.HasPrefix(arg, "-") && arg != "-":
				fail("unknown option '%s'", arg)
			default:
				files = append(files, arg)
			}
		}
	}

	// Resolve the strip set: the explicit set if any was named, else the default,
	// then subtract the --no-<sugar> removals.
	base := sugar.Defaults
	if explicitUsed {
		base = explicit
	}
	sugars := sugar.NewSet()
	for s := range base {
		if !removals.Has(s) {
			sugars.Add(s)
		}
	}

	process := func(text string) string {
		if asHTML {
			out := sugar.StripHTML(text, sugars)
			if tableFormat != nil {
				out, _ = sugar.ConvertHTMLTables(out, *tableFormat)
			}
			return out
		}
		out := sugar.StripPlainText(text, sugars)
		if tableFormat != nil {
			out, _ = sugar.ConvertMarkdownTables(out, *tableFormat)
		}
		return out
	}

	input := readInput(files)
	if _, err := os.Stdout.WriteString(process(input)); err != nil {
		fail("write failed: %v", err)
	}
}

func readInput(files []string) string {
	if len(files) == 0 {
		return readStdin()
	}
	var b strings.Builder
	for _, path := range files {
		if path == "-" {
			b.WriteString(readStdin())
			continue
		}
		data, err := os.ReadFile(path)
		if err != nil {
			fail("cannot read file '%s'", path)
		}
		b.Write(data)
	}
	return b.String()
}

func readStdin() string {
	data, err := io.ReadAll(os.Stdin)
	if err != nil {
		fail("cannot read stdin: %v", err)
	}
	return string(data)
}
