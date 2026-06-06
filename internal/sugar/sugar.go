// Package sugar is the portable text-stripping core behind the `sugarfree` CLI.
//
// It mirrors the Swift `SugarStripper` / `TableConverter` that power the macOS
// menu-bar app. The two implementations are kept in lock-step by a shared golden
// corpus (Tests/SugarParityCorpus.json) that both test suites assert against —
// parity is by test, not by shared code, so any rule change must touch both
// languages and the corpus.
package sugar

// Sugar is a kind of formatting "sugar" that can be stripped from text. The set
// the user enables is removed across whichever representation carries it (HTML
// tags/styles or markdown markers). RTF lives only in the Swift app (AppKit).
type Sugar string

const (
	Bold          Sugar = "bold"
	Italic        Sugar = "italic"
	Underline     Sugar = "underline"
	Strikethrough Sugar = "strikethrough"
	Heading       Sugar = "heading"
)

// All is every sugar, in the canonical order the strippers apply HTML rules.
var All = []Sugar{Bold, Italic, Underline, Strikethrough, Heading}

// Defaults are the everyday annoyances stripped unless the user picks otherwise.
// Bold + italic mirror the app's default-on set (Swift `Sugar.defaults`).
var Defaults = NewSet(Bold, Italic)

// Set is a set of sugars to strip.
type Set map[Sugar]bool

// NewSet builds a Set from the given sugars.
func NewSet(sugars ...Sugar) Set {
	s := make(Set, len(sugars))
	for _, sug := range sugars {
		s[sug] = true
	}
	return s
}

// Has reports whether the sugar is in the set.
func (s Set) Has(sug Sugar) bool { return s[sug] }

// Add inserts a sugar.
func (s Set) Add(sug Sugar) { s[sug] = true }

// Remove deletes a sugar.
func (s Set) Remove(sug Sugar) { delete(s, sug) }
