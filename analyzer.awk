#!/usr/bin/awk -f

# Usage: awk -f [me] [-v minratio=0.xx] files...
#
# Looks for similar lines (paragraphs) in the given text files.
# The primary intent is to scan stripped DITA topics for potential reuse.
# You could also use it to catch minor inconsistencies in a document set.
#
# Adjust the minratio variable to loosen or tighten the matching.
# Set minratio=1 to skip fuzzy matching altogether.

BEGIN {
	if( !minratio )   minratio = 0.95;
	if( !quiet )      quiet = 0;
	if( !minlength )  minlength = 0;  # skip blocks smaller than this
	if( !progress )   progress = 100; # status msg each number of blocks
	if( !ignorecase ) ignorecase = 0; # tolower() everything if 1
}

length($0) < minlength { next; } 

{
	# preprocessing

	gsub( /^[ \t]*/, "" ); # get rid of leading spaces
	gsub( /[ \t]*$/, "" ); # and trailing spaces
	gsub( /\[\]/, "" ); # get rid of spurious image links
	if( ignorecase ) { $0 = tolower($0); }
}

/^ *$/ { next; } # delete blank lines

{
	# scoop up everything else into a ginormous array
	# key: FILENAME,linenum = string

	paras[FILENAME,FNR] = $0;
	++paracount;
	next;
}

END {
	# Go looking for similar paragraphs!
	if( !quiet ) print "Analyzing", paracount, "paragraphs..." >"/dev/stderr";

	progresscnt = 0;
	for( s in paras ) {
		repeat = 0;
		for( s1 in paras ) {
			# don't test against itself, and don't test short vs long strings
			# (short vs long strings can have a distance that's greater than the minratio,
			# even if the short string is an exact subset of the longer string)
			# This can save massive amounts of time by skipping unproductive comparisons.
			if( (s != s1) && (lev_ratio(paras[s], paras[s1], 
				abs(length(paras[s])-length(paras[s1])))>=minratio) ) { 
				if( minratio < 1 ) {
					d = levenshtein( paras[s], paras[s1] );
					r = lev_ratio( paras[s], paras[s1], d );
				} else {
					# special case: minratio = 1, skip the fuzzy match entirely
					r = (paras[s] == paras[s1]);
				}
				if( r >= minratio ) {
					split( s, a, SUBSEP );
					split( s1, b, SUBSEP );
					if( !repeat ) {
						print "\nMatches for", a[1], "block", a[2] ":";
						print paras[s];
						repeat = 1;
					}
					print "\t" b[1], "block", b[2], "(ratio", r "):";
					print "\t" paras[s1];
				}
			}
		}
		++progresscnt;
		if( !quiet && int(progresscnt/progress) == (progresscnt/progress) ) {
			print "Analyzed", progresscnt, "of", paracount "..." >"/dev/stderr";
		}
		delete paras[s]; # don't test strings twice, cuts processing time in half
	}
	if( !quiet ) print "Done!" >"/dev/stderr";
}


# Adapted from:
# https://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Levenshtein_distance (C version)
function levenshtein(str1, str2,   
			s1, s2, lev_col, s1len, s2len, x, y, t1, t2, t3, t, lastdiag, olddiag) {

	if( str1 == str2 ) return 0; # skip the fuzz if they're identical

	# TODO: strip leading tags from bulleted/numbered list items

	s1len = length(str1);
	s2len = length(str2);

	split(str1, s1, "");
	split(str2, s2, "");

	for( y = 1; y <= s1len; ++y ) {
		lev_col[y] = y;
	}
	for( x = 1; x <= s2len; ++x ) {
		lev_col[0] = x;
		y = 1;
		for( lastdiag = x-1; y <= s1len; ++y ) {
			olddiag = lev_col[y];
			t1 = lev_col[y]+1;
			t2 = lev_col[y-1]+1;
			t3 = lastdiag + (s1[y] == s2[x] ? 0 : 1);
			t = t1 < t2 ? t1 : t2;
			t = t < t3 ? t : t3;
			lev_col[y] = t;
			lastdiag = olddiag;
		}
	}
	return( lev_col[s1len]);
}

# Compute ratio (cribbed from Python tutorial at:
# https://www.datacamp.com/community/tutorials/fuzzy-string-python)
function lev_ratio( str1, str2, dist,   l1, l2 ) {
	l1 = length(str1);
	l2 = length(str2);
	if( !(l1+l2) ) return 0; # skip blank lines
	return( (l1+l2 - dist) / (l1+l2) );
}

# Absolute value
function abs(x) {
	return x<0 ? -x : x ;
}
