#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use File::Find;
use File::Copy;
use version; our $VERSION = qv('1.0.0');

=begin comment
Function sanitize_file_name sanitizes the file name by removing spaces, commas, dashes and dots
except the dot before the file extension.
=end comment

=cut
sub sanitize_file_name {
    my ($file_name, $replace_char) = @_;

    # Remove spaces
    $file_name =~ s/\s+/$replace_char/g;

    # Remove commas and dashes
    $file_name =~ s/[,-]+/$replace_char/g;

    # Replace consecutive underscores with a single underscore
    $file_name =~ s/(?<!\.)_+/$replace_char/g;

    # Replace dots with underscores, except the one before the file extension
    $file_name =~ s/(?<=\b)(?<!\.)\.(?![^.]+$)/$replace_char/g;

    return $file_name;
}


# Function to get the file name from a path
sub get_file_name {
    my ($file) = @_;
    my @path = split /\//, $file;
    return $path[-1];
}

# Function to rename the file
sub rename_file {
    my ($old_name, $new_name) = @_;
    my $old_file_name = get_file_name($old_name);
    my $new_file_name = get_file_name($new_name);

    if ($old_file_name ne $new_file_name) {
        rename $old_name, $new_name;
        print "File renamed: '$old_file_name' -> '$new_file_name'\n";
    }
}

# Function to process files in a directory
sub process_files {
    my ($file, $extension, $replace_char) = @_;

    return unless -f $file;
    return unless $file =~ /\.(?:$extension)$/i;

    my $new_file_name = sanitize_file_name($file, $replace_char);
    my $new_full_path = $file;
    $new_full_path =~ s/([^\/]+)$/$new_file_name/;
    rename_file($file, $new_full_path);
}

my $replace_char = '_'; # Default replacement character
my $extension = 'pdf';  # Default file extension
my $help;

# Parse command line options
GetOptions(
    'replace=s' => \$replace_char,
    'ext=s' => \$extension,
    'help' => \$help
) or die 'Error in command line arguments\n';

# Display help message
if (defined $help) {
    print "Usage: $0 [options] DIRECTORY\n" or croak $!;
    print "Options:\n";
    print "  --replace=CHAR     Replace spaces with specified CHAR (default: underscore)\n";
    print "  --ext=EXTENSION    Process files with specified EXTENSION (default: pdf)\n";
    print "  --help             Display this help message\n";
    exit;
}

# Check if a directory is provided
if (@ARGV != 1) {
    print "Error: No directory provided\n";
    die "Usage: $0 [options] DIRECTORY\n";
}

my $directory = $ARGV[0];

# Check if the directory exists
if (-d $directory) {
    find(sub { process_files($File::Find::name, $extension, $replace_char) }, $directory);
} else {
    die "Error: Directory '$directory' not found\n";
}
