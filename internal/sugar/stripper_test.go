package sugar

import "testing"

func TestStripPlainTextBoldBeforeItalic(t *testing.T) {
	// Stripping only italic must not chew a **bold** run into *bold*.
	if got := StripPlainText("**bold**", NewSet(Italic)); got != "**bold**" {
		t.Errorf("got %q, want %q", got, "**bold**")
	}
}

func TestStripPlainTextDefaults(t *testing.T) {
	if got := StripPlainText("**b** *i*", Defaults); got != "b i" {
		t.Errorf("got %q, want %q", got, "b i")
	}
}

func TestStripHTMLHeadingBackreference(t *testing.T) {
	// The backreference must keep the open/close levels matched.
	if got := StripHTML("<h1>a</h1><h3>b</h3>", NewSet(Heading)); got != "ab" {
		t.Errorf("got %q, want %q", got, "ab")
	}
}

func TestStripHTMLNoDotAllAcrossNewlines(t *testing.T) {
	// Parity with Swift: HTML tag patterns are not dotall, so a tag spanning a
	// newline is left intact.
	in := "<b>line1\nline2</b>"
	if got := StripHTML(in, NewSet(Bold)); got != in {
		t.Errorf("got %q, want unchanged %q", got, in)
	}
}
