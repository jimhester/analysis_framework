#!/usr/bin/env perl
use warnings;
use strict;
use autodie qw(:all);
###############################################################################
# By Jim Hester
# Created: 2013 Apr 19 10:57:28 AM
# Last Modified: 2013 Sep 23 01:34:03 PM
# Title:add_external_scripts.pl
# Purpose:Add external scripts as code blocks
###############################################################################
# Code to handle help menu and man page
###############################################################################
use Getopt::Long;
use Pod::Usage;
my %languages = ( '.r'   => 'r',         #r
                  '.sh'  => 'bash',      #bash
                  '.pl'  => 'perl',      #perl
                  '.py'  => 'python',    #python
                  '.rb'  => 'ruby',      #ruby
                  '.zsh' => 'zsh',       #zsh
                );

my @suffixes = keys %languages;
my @engines  = map { $languages{$_} } keys %languages;
my %args     = ( languages => \%languages );
GetOptions( \%args, 'languages=s%', 'help|?', 'man' )
  or pod2usage(2);
pod2usage(2) if exists $args{help};
pod2usage( -verbose => 2 ) if exists $args{man};
pod2usage("$0: No files given.") if ( ( @ARGV == 0 ) && ( -t STDIN ) );
###############################################################################
# add_external_scripts.pl
###############################################################################

#allow comma separated arguments
@engines  = expand_commas( \@engines );
@suffixes = expand_commas( \@suffixes );

#create group matches
my $suffix_group = generate_match_group( \@suffixes );
my $engine_group = generate_match_group( \@engines );

#read all data
my $data = slurp();

my $has_mtime_function = qr/mtime \s+ <- \s+ function [(] files [)] /xmsi;

#find all already included scripts
#TODO check paths for includes?
my %included_scripts;

my $included_regex =
  qr/``` { [^`]+ read_chunk [\('\s]+ ([\S]+ $suffix_group) .*? engine [\s='"]+ $engine_group/xims;

while ( $data =~ m/$included_regex/g ) {
  $included_scripts{ remove_path( remove_suffix($1) ) }++;
}

my $sub_regex =
  qr/ ``` ( {r [^}`]+ ) } ( [^`]+ ) ``` /xims;

$data =~ s{$sub_regex}{
  my($options, $block) = ($1, $2);
  my($pre)='';
  my @files;
  #do not include output files in the dependencies
  while($block =~ m{ ((?<!>\ )\S+) }xmsg){
    my ($rel_path) = relative_path($1);
    my ($abs_path) = glob($rel_path);
    if(-f $abs_path){

      if($1 =~ m{ ([\S]+ ($suffix_group) ) }xms){
       push @files, $rel_path;
       my ($script_name, $suffix) = ($1, $2);
        $pre .= generate_script_include_block($script_name, $suffix);
      }
    }
  }
  $options = generate_cache_dependency_options($options, \@files);
  $pre . '```' . $options . '\}' . $block . '```';
}eg;

print $data;

sub generate_cache_dependency_options {
  my ( $options, $filename_ref ) = @_;
  return $options unless @{$filename_ref};
  my %dependencies = map { $_ => 1 } @{$filename_ref};

  my $cache_extra_regex =
    qr/ ( cache [.] extra \s* = \s* mtime ) [(] (?:c[(])* ([^)]+) [)] [)]* /xims;
  if ( $options =~ m/$cache_extra_regex/ ) {

    #add additional scripts to cache.extra if not already there
    $options =~ s{$cache_extra_regex}{
      my($before, $files) = ($1, $2);
      while($files =~ m/'([^']+)'/g){
        $dependencies{$1}++;
      }
    $before .= '(' . generate_concat(sort keys %dependencies ) . ')';
    }eg;
  }
  else {
    $options .= ', cache.extra=mtime('
      . generate_concat( sort keys %dependencies ) . ')';
  }
  return $options;
}

sub generate_concat {
  return
    'c(' . join( ', ', map { q['] . $_ . q['] } @_ ) . ')';
}

sub generate_script_include_block {
  my ( $script_name, $suffix ) = @_;
  my $label = remove_path( remove_suffix($script_name) );

  #add include blocks to scripts which are not already included
  if ( not exists $included_scripts{$label} ) {

    #TODO this may be broken if your shells path does not use which
    my $relative_path = relative_path($script_name);
    my ($abs_path) = glob($relative_path);
    if ( -e $abs_path ) {

      #convert to relative path
      $included_scripts{$label}++;
      return ( build_script_chunk( $relative_path, $label, $suffix ) );
    }
  }

  #add include blocks to scripts which are not already included
  if ( not exists $included_scripts{$label} ) {

  }
}

sub relative_path {
  my ($script_name) = @_;
  $script_name =~ s/[']//g;
  my($full_path) = glob($script_name);

  return $script_name if ($script_name and -e $script_name) or ($full_path and -e $full_path);

  #TODO this may be broken if your shells path does not use which
  my $relative_path = `/usr/bin/which --show-tilde --show-dot -- '$script_name' 2>&-`;
  chomp $relative_path;
  return $relative_path;
}

#allow comma separated lists for arguments
sub expand_commas {
  my ($array_ref) = @_;
  return split /,/, join( ',', @{$array_ref} );
}

#make a quoted match_group for the array
sub generate_match_group {
  my ($array_ref) = @_;
  return '(?:' . join( "|", map {quotemeta($_)} @{$array_ref} ) . ')';
}

sub build_script_chunk {
  my ( $path, $label, $suffix ) = @_;

  #should always be true
  die unless exists $languages{$suffix};

  my ($engine) = $languages{$suffix};

  return << "END_CHUNK";
```{r, echo=F, cache=FALSE}
read_chunk('$path', labels='$label')
```
```{r $label, engine='$engine', eval=FALSE, cache=FALSE}
```
END_CHUNK
}

sub slurp {
  local $/ = undef;
  return scalar <>;
}

sub remove_suffix {
  my $file = shift;
  $file =~ s{ [.] .* }{}xms;
  return $file;
}

sub remove_path {
  my $file = shift;
  $file =~ s{ .* [\/] }{}xms;
  return $file;
}
###############################################################################
# Help Documentation
###############################################################################

=head1 NAME

add_external_scripts.pl - Add external scripts as code blocks

=head1 VERSION

0.0.1

=head1 USAGE

Options:
      -engine
      -suffix
      -help
      -man               for more info

=head1 OPTIONS

=over

=item B<-engine>

Engines to search in for external scripts

=item B<-suffix>

Program suffixes which denote external scripts

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<add_external_scripts.pl>  Add external scripts as code blocks

=cut

