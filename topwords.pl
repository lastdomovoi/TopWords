#!/usr/bin/perl

# v0.01 - initial.
# v0.02 - Min word length limit added.

# Usage: perl topwords.pl /f:<file path>

use strict;
use warnings;
use Data::Dumper;
use utf8;
use open qw( :encoding(UTF-8) :std );
use v5.12;  # minimal for unicode string feature

use constant RE_WORDS_DELIMITERS => '[\W_\d]+';

my @languages = ( "English", "Russian (default)" );

my %lang_regexp =
(
	"English" => '[a-z]+',
);

sub parse_input_file;
sub parse_string;
sub print_top_words;

## MAIN #####################################################################
my $out = *STDOUT;
my $infile;
my %topwords = ();
my $min_word_length = 1;

#binmode(STDIN, ':utf8' );
#binmode(STDOUT, ':utf8' );

foreach my $arg (@ARGV)
{
	if ($arg =~ m{^(-|/)f:(?<infile>.*)}i)
	{
		$infile = $+{infile};
		printf $out "Input file: ".$infile."\n";
	}
	elsif ($arg =~ m{^(-|/)ml:(?<len>\d+)}i)
	{
		$min_word_length = $+{len};
		printf $out "Minimum word length: ".$min_word_length."\n";
	}
	else
	{
		die "Usage: $0 /f:<file path> /ml:<minimum word length>\n"
	}
}

if (!defined($infile))
{
	die "Error: input file is not defined\n";
}

parse_input_file($infile);

foreach my $lang (@languages)
{
	print_top_words($lang, 10);
}

exit;

#############################################################################
sub parse_input_file()
{
	my $filepath = $_[0];

	my $ret = open(my $fh, $filepath);
	if (!$ret)
	{
		die "Error: open(".$filepath.") failed: ".$!."\n";
	}

	printf $out "Parsing ".$filepath."...\n";


	while (!eof($fh))
	{
		defined(my $str = <$fh>)
		    or die "Reading failed for ".$filepath.": ".$!."\n";

		parse_string($str);
	}
}

#############################################################################
sub parse_string()
{
	my ($str) = @_;

	chomp($str);

	if ($str eq "")
	{
		return;
	}

	my @words = split RE_WORDS_DELIMITERS, lc $str;

	foreach my $word (@words)
	{
		next if $word eq "";

		next if length($word) < $min_word_length; 

		foreach my $lang (@languages)
		{
			if (!defined($lang_regexp{$lang}))
			{
				# default language
				$topwords{$lang}{$word}++;
				last;
			}

			if ($word =~ m{$lang_regexp{$lang}})
			{
				$topwords{$lang}{$word}++;
				last;
			}
		}
	}
}

#############################################################################
sub print_top_words()
{
	my ($lang, $limit) = @_;
	my $pos = 1;

	if (!defined($lang))
	{
		$lang = "Russian (default)";
	} 

	printf $out
		"Top words (language: ".$lang.")\n"
		."position   count   word\n";

	foreach my $key (
		sort {$topwords{$lang}{$b} <=> $topwords{$lang}{$a}}
		keys %{$topwords{$lang}})
	{
		printf $out "%7d. %7d - %s\n", 
		      $pos++, $topwords{$lang}{$key}, $key;

		if (defined($limit))
		{
			last if $pos > $limit;
		}
	}

	printf $out "\n";
}
