package sugar

import (
	"encoding/json"
	"os"
	"path/filepath"
	"runtime"
	"testing"
)

// corpusCase is one shared parity case. The same JSON drives the Swift
// SugarParityCorpusTests, so Go and Swift assert identical behavior.
type corpusCase struct {
	Name     string   `json:"name"`
	Input    string   `json:"input"`
	Format   string   `json:"format"` // "markdown" | "html"
	Sugars   []string `json:"sugars"` // sugar names to strip
	Tables   *string  `json:"tables"` // "yaml" | "toml" | null
	Expected string   `json:"expected"`
}

// corpusPath resolves Tests/SugarParityCorpus.json relative to this source file
// (…/internal/sugar/corpus_test.go → repo root → Tests/…).
func corpusPath(t *testing.T) string {
	t.Helper()
	_, file, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("runtime.Caller failed")
	}
	root := filepath.Join(filepath.Dir(file), "..", "..")
	return filepath.Join(root, "Tests", "SugarParityCorpus.json")
}

func applyCase(c corpusCase) string {
	sugars := NewSet()
	for _, name := range c.Sugars {
		sugars.Add(Sugar(name))
	}
	var format Format
	if c.Tables != nil {
		if *c.Tables == "toml" {
			format = TOML
		} else {
			format = YAML
		}
	}

	if c.Format == "html" {
		out := StripHTML(c.Input, sugars)
		if c.Tables != nil {
			out, _ = ConvertHTMLTables(out, format)
		}
		return out
	}
	out := StripPlainText(c.Input, sugars)
	if c.Tables != nil {
		out, _ = ConvertMarkdownTables(out, format)
	}
	return out
}

func TestParityCorpus(t *testing.T) {
	data, err := os.ReadFile(corpusPath(t))
	if err != nil {
		t.Fatalf("read corpus: %v", err)
	}
	var cases []corpusCase
	if err := json.Unmarshal(data, &cases); err != nil {
		t.Fatalf("parse corpus: %v", err)
	}
	if len(cases) == 0 {
		t.Fatal("corpus is empty")
	}

	for _, c := range cases {
		c := c
		t.Run(c.Name, func(t *testing.T) {
			got := applyCase(c)
			if got != c.Expected {
				t.Errorf("case %q\n  input:    %q\n  expected: %q\n  got:      %q",
					c.Name, c.Input, c.Expected, got)
			}
		})
	}
}
