#!/usr/bin/env sh
# Generates a test file `test_cat.txt` with many different line types
# to test all `cat` flags: -n, -b, -s, -v, -E, -T, -A, -e, -t, etc.

OUT=test_cat.txt
rm -f "$OUT"

cat > "$OUT" <<'EOF'
# Section 1: normal lines
First normal line.
Second normal line with trailing spaces.    
Line with tab ->	<- here is a tab
Line with multiple	tabs	and	columns	(3 tabs)

# Section 2: blank lines and multiple blank lines
Line before blank block.


[Line after two blank lines]



[Line after three blank lines]

# Section 3: lines with only spaces or tabs
(Four-space line)
    
(Tab line)
	

# Section 4: very long lines
EOF

# Add a very long line (~10k 'A') using Python
python3 - <<PY >> "$OUT"
print("LONG_LINE_START")
print("A" * 10000)
print("LONG_LINE_END")
PY

cat >> "$OUT" <<'EOF'

# Section 5: control characters (non-printing)
# SOH (\x01), BEL (\x07), ESC (\x1B), DEL (\x7F)
EOF

printf '\x01SOH_byte_here\n' >> "$OUT"
printf 'Before_BEL_test: \x07 (BEL may beep)\n' >> "$OUT"
printf 'ESC_color_test: \x1B[31mRED\x1B[0m back to normal\n' >> "$OUT"
printf 'Ends_with_DEL:' >> "$OUT"
printf '\x7F' >> "$OUT"
printf '\n' >> "$OUT"

cat >> "$OUT" <<'EOF'

# Section 6: CRLF-style lines
CRLF_line_windows_style\r
CRLF_line_windows_style_bis\r

# Section 7: symbols for -E/$ testing
Percentage: 100% percent
Dollar sign at end of line $

# Section 8: UTF-8 / multibyte
Emoji line: 😄 🚀
Accented characters: àèìòù ñ ç ü

# Section 9: list / miscellaneous
- first item
- second item	with	tab
- third item

# End of file
EOF

echo "File created: $OUT (size: $(wc -c < $OUT) bytes)"
echo "Try commands like:"
echo "  cat -n $OUT        # number all lines"
echo "  cat -b $OUT        # number non-blank lines"
echo "  cat -s $OUT        # squeeze multiple blank lines"
echo "  cat -E $OUT        # show $ at en

