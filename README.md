# Reuse analyzer

This is a fairly simple Awk script
to analyze one or more text files
and report on matches or near-matches.
It uses the [Levenshtein distance algorithm](https://en.wikipedia.org/wiki/Levenshtein_distance)
to perform fuzzy matches on lines of text.

It generates a report, showing matches and the score for each.
The minimum score can be adjusted on the command line.
You can use the report to find strings to reuse,
or catch inconsistencies.

## Preparing the text

Use plain text, stripped of all markup.
Each line should be a single sentence or block (paragraph).
For DITA, use a script like this
to prepare your text
(requires the `org.lwdita` plugin):

```sh
dita --format=markdown_github --input=my.bookmap --args.rellinks=none
cd out
rm index.md
for i in *.txt; do
	f=`basename $i .md`
	pandoc -t plain —wrap=none -o $f.txt $i
done
```

This puts each block element on a single line.

For word processor documents, save as text.

## Running the script

Use this command to run the script:

`awk -f analyzer.awk `[`-v `*option*`=`*value*]... *files*...

You can specify multiple options. Available options are:

minratio (default: 0.95)
:  The minimum fuzzy matching ratio to report on. A value of 1 turns off fuzzy matching, reporting only exact matches.

minlength (default: 0)
:  The minimum string length to compare.

ignorecase (default: 0)
:  Set to 1 to make matching case-insensitive.

quiet (default: 0)
:  Set to 1 to suppress status and progress messages.

progress (default: 100)
:  Prints a status/progress message after comparing this many blocks.

## Performance

Fuzzy matching is a processor-intensive activity,
especially when using a script.
Limiting the number of matches needed is the most effective strategy
to improve performance.
The script uses these techniques to avoid doing fuzzy matches:

*  Blocks (lines of text) are not compared to themselves.
*  After comparing a block to everything else,
   the analyzer throws out the block to avoid duplicate comparisons.
   This by itself cuts runtime in half.
*  If two blocks have a length different enough
   that the result could never reach `minratio`,
   they are not compared.
   This makes a big difference in the time needed.
*  The script checks for an exact match before attempting the fuzzy match.

A small to mid-size document set (about 2200 paragraphs)
takes just under 5 minutes to analyze on a late-2013 iMac.
You can compile the script, using *awka*,
for a performance boost
(the same document set takes 1-1/2 minutes with the compiled version).
To compile the script, use:

	awka -X -f analyzer.awk
	mv awka.out analyzer

## Limitations vs. commercial offerings

Commercial reuse analyzers tend to have nicer interfaces,
and some meant for DITA
can build a collection (or library) file of strings
and automatically apply them to your topics.

On the other hand,
if your budget is very limited
and you have a small document set to analyze,
this one might be exactly what you need.

