#!/usr/bin/perl
#
# Generate README.md files for all packages.
# These READMEs are presented to users that (accidentally)
# visit a package home page.
#
# 2019-12-25 
# Frank Bergmann <frank.bergmann@project-open.com>

use LWP::Simple qw(get);
use HTML::TreeBuilder 5 -weak;
use HTML::Element;


if (@ARGV != 0) {
    die "
all-github-readme: This command doesn't take arguments.
Usage:
	all-github-readme

\n\n"
}

$date = `/bin/date +"%Y-%m-%d"`;
$time = `/bin/date +"%H-%M"`;
$debug = 1;
$base_dir = "/web/projop";			# no trailing "/"!
$packages_dir = "$base_dir/packages";		# no trailing "/"!

# Remove trailing \n from date & time
chomp($date);
chomp($time);

# Main loop: use "find" to get the list of all packages
#
open(FILES, "cd $packages_dir; ls -1 |");
while (my $package=<FILES>) {
        # Remove trailing "\n"
        chomp($package);

	print "update_readme_files: found local package: '$package'\n" if ($debug > 2);
#	next if (!($package =~ /intranet-hr$/));
#	next if ($package ne "acs-admin");
#	next if ($package ne "intranet-adrtel-sap");

	# Exclude internal or customer packages
	next if ($package =~ /^intranet-trans/);		# Exclude translation stuff
	next if ($package =~ /^intranet-cust-/);		# Exclude customer specific
	next if ($package =~ /^ref-/);				# Exclude OACS data packages
	next if ($package =~ /^upgrade-/);			# Exclude upgrade packages
	next if ($package =~ /\.perl$/);			# Exclude perl files

	# Exclude specific packages
	next if ($package eq "intranet-oryx-ts-extension");		# outdated
	next if ($package eq "acs_admin_tools");			# tools
	next if ($package eq "baseCVS");				# internal
	next if ($package eq "CVSROOT");				# internal
	next if ($package eq "garbage");				# 
	next if ($package eq "psets");  				# 

	print "update_readme_files: updating '$package'\n";
	update_readme_file($package);
}
close(FILES);

exit 0;


sub update_readme_file {
    (my $package) = @_;
    
    $readme_file = $packages_dir . "/" . $package . "/README.md";
    print "update_readme_file: readme_file=$readme_file\n" if ($debug > 2);


    # ---------------------------------------------------
    # Get and parse the file
    my $url = "https://www.project-open.net/en/package-$package?no_template_p=1";
    print "update_readme_file: getting url=$url\n" if ($debug);
    my $html = get $url;

    if (!defined $html) { 
	print "update_readme_file: Error fetching url=$url\n" if ($debug >= 0);
	return; 
    }
    
    # Replace &nbps; by normal spaces and convert relative in absolute links
    $html =~ s/&nbsp;/\ /g;
    $html =~ s/\=\"\//\=\"http\:\/\/www.project-open.com\//g;

    # Parse the HTML tree
    my $tree = HTML::TreeBuilder->new;
    $tree->parse($html);

    my $title = $tree->look_down('_tag', 'title')->as_text();
    print "update_readme_file: title=$title\n" if ($debug);


    # ---------------------------------------------------
    # Remove <meta>, <style> and <div>
    $tree->delete_ignorable_whitespace();
    my @metas = $tree->find_by_tag_name('meta'); foreach my $meta (@metas) { $meta->delete(); }
    my @styles = $tree->find_by_tag_name('style'); foreach my $style (@styles) { $style->delete(); }
    my @divs = $tree->find_by_tag_name('div'); foreach my $div (@divs) { $div->delete(); }

    my @tags = $tree->look_down("xxx", undef);
    foreach my $tag (@tags) {
	my $tagname = $tag->tag();
	print "update_readme_file: tagname=$tagname\n" if ($debug > 2);
	if ($tagname eq "br") { $tag->delete(); }
    }


    # ---------------------------------------------------
    # Parse <h2>s of Package Documentation
    #
    my @tags = $tree->look_down("xxx", undef);
    my $h2 = "";
    my %h2_hash = ();
    my @h2_list = ();
    foreach my $tag (@tags) {
	my $tagname = $tag->tag();
	if ("h2" eq $tagname) { 
	    $h2 = $tag->as_trimmed_text(); 
	    push @h2_list, $h2;
	    $tag->delete();
	}
	if ("table" eq $tagname) { 
	    $h2_body = $tag->as_HTML(); 
	    $h2_hash{$h2} = $h2_body;
	    $tag->delete();
	}
    }

    foreach my $h2 (@h2_list) {
	print "update_readme_file: h2=$h2\n" if ($debug > 2);
	print "update_readme_file: h2=$h2_hash{$h2}\n" if ($debug > 2);
    }



    # ---------------------------------------------------
    # Parse <h1>s of main sections
    #
    my @tags = $tree->look_down("xxx", undef);
    my $h1 = "";
    my $first_h1 = "";
    my $h1_html = "";
    my %h1_hash = ();
    my @h1_list = ();
    foreach my $tag (@tags) {
	my $tagname = $tag->tag();
	print "update_readme_file: h1_tag=$tagname\n" if ($debug > 2);

	next if ($tagname eq "");
	next if ($tagname eq "head");
	next if ($tagname eq "html");
	next if ($tagname eq "body");

	if ("h1" eq $tagname) {
	    $h1 = $tag->as_trimmed_text(); 
	    if ("" eq $first_h1) { $first_h1 = $h1; xxx; }
	    push @h1_list, $h1;
	    $tag->delete();
	} else {
	    next if ("" eq $h1);
	    $h1_body = $tag->as_HTML();
	    print "update_readme_file: h1_body=$h1_body\n" if ($debug > 2);
	    my $html = "";
	    if (exists($h1_hash{$h1})) { $html = $h1_hash{$h1}; }
	    $html = $html . $h1_body;
	    print "update_readme_file: html='$html'\n" if ($debug > 2);
	    $h1_hash{$h1} = $html;
	    $tag->delete();
	}

    }

    my $first_h1_text = "";
    if (exists($h1_hash{$first_h1})) { $first_h1_text = $h1_hash{$first_h1}; }


    foreach my $h1 (@h1_list) {
	print "update_readme_file: h1=$h1\n" if ($debug > 1);
	print "update_readme_file: h1=$h1_hash{$h1}\n" if ($debug > 2);
    }
    print "update_readme_file: tree=", $tree->dump(), "\n" if ($debug > 1);
    print "update_readme_file: tree=", $tree->as_HTML(), "\n" if ($debug > 1);

    my $result = "# " . $title . "\n" .
	"This package is part of ]project-open[, an open-source enterprise project management system.\n\n" .
	"For more information about ]project-open[ please see:\n" .
	"* [Documentation Wiki](https://www.project-open.com/en/)\n" .
	"* [V5.0 Download](https://sourceforge.net/projects/project-open/files/project-open/V5.0/)\n" .
	"* [Installation Instructions](https://www.project-open.com/en/list-installers)\n" .
	"\n" .
	"About $title:\n\n" .
	$first_h1_text . "\n\n";



    # ---------------------------------------------------
    # Add online documentation sections
    #
    $result = $result . "# Online Reference Documentation\n\n";
    foreach my $h2 (@h2_list) {
	$result = $result . "## $h2\n\n";
	$result = $result . "$h2_hash{$h2}\n\n";
    }


    # ---------------------------------------------------
    # Write to README.md
    #
    system("chmod -f ug+w $readme_file");
    open(F, "> $readme_file");
    print F $result;
    close(F);
}



exit 0;

