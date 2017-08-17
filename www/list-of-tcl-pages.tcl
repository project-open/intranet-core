# /packages/intranet-core/www/list-or-tcl-pages.tcl
#
# Copyright (C) 1998-2004 various parties
# The code is based on ArsDigita ACS 3.4
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_page_contract { 
    Shows the list of all TCL and ADP pages in the system.
    This list can be used for localization, security testing
    etc.

    @author frank.bergmann@project-open.com
} {
    { format "html" }
}

# ---------------------------------------------------------------
# Security & Defaults
# ---------------------------------------------------------------


set page_title "List of Pages with Visits"
set user_id [auth::require_login]
set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "
set root_dir [im_root_dir]

if {[regexp {/([a-z0-9A-Z]+)$} $root_dir match server_name]} {
    # Nada, worked...
} else {
    ad_return_complaint 1 "Could not determine server_name from '$root_dir'"
}

# ad_return_complaint 1 $server_name


# ---------------------------------------------------------------
# Installed & Enabled Packages
# ---------------------------------------------------------------

set site_nodes [list]
set site_node_sql "select distinct name from site_nodes where object_id is not null order by name"
db_foreach site_nodes $site_node_sql {
    lappend site_nodes $name
    set site_node_hash($name) $name
}

# ad_return_complaint 1 $site_nodes


# ---------------------------------------------------------------
# Admin pages that don't need to be localized
# ---------------------------------------------------------------

set admin_path_hash(/intranet-dynfield/) 1


# ---------------------------------------------------------------
# List of pages
# ---------------------------------------------------------------

set packages_dir "$root_dir/packages"
set packages_dir_len [expr [string length $packages_dir] + 0]
set tcl_file_list [im_exec find $packages_dir -noleaf -type f]
foreach tcl_file_abs $tcl_file_list {
    set tcl_file_rel [string range $tcl_file_abs $packages_dir_len end]

    # Only show files in /www/ folder
    if {[regexp {^(.*)/www/(.*)$} $tcl_file_rel match path tcl_file_body]} { 
	# Skip files if we don't find the site_node
	set path_without_leading_slash [string range $path 1 end]
	if {![info exists site_node_hash($path_without_leading_slash)]} { continue }

	set tcl_file_without_www "$path/$tcl_file_body"

    } else {
	continue; 	# Skip library files 
    }

    # /intranet-core translates into /intranet. This is the only exception.
    if {[regexp {^/intranet-core/(.*)} $tcl_file_without_www match rest]} { 
	set tcl_file_without_www "/intranet/$rest"
    }

    if {[regexp {/CVS/} $tcl_file_without_www]} { continue };     # Skip CVS files
    if {![regexp {^/intranet} $tcl_file_without_www]} { continue };     # Skip non-]po[ files

    # Cut off the trailing .tcl or .adp extension
    if {[regexp {^(.*)\.tcl$} $tcl_file_without_www match base]} { set tcl_file_without_www $base }
    if {[regexp {^(.*)\.adp$} $tcl_file_without_www match base]} { set tcl_file_without_www $base }

    # Don't translate admin pages
    foreach p [array names admin_path_hash] {
	set len [expr [string length $p] - 1]
	if {$p eq [string range $base 0 $len]} { continue }
    }

    set page_hash($base) 1

}

set pages [qsort [array names page_hash]]
set page_count [llength $pages]

# ad_return_complaint 1 "<pre>page_count=$page_count<br>[join $pages "<br>"]</pre>"


# ---------------------------------------------------------------
# Log files
# ---------------------------------------------------------------

set log_dir "$root_dir/log"
set log_dir_len [expr [string length $log_dir] + 1]
set log_file_list [im_exec find $log_dir]
# ad_return_complaint 1 "<pre>[join $log_file_list "<br>"]</pre>"
foreach log_file_abs $log_file_list {

    # Discard everything except for <server_name>*.log files
    if {![regexp {/([^/]+)$} $log_file_abs match log_file_name]} { continue }
    if {![regexp "^${server_name}.*\.log" $log_file_name match]} { continue }

    set log_file_contents [im_exec cat $log_file_abs]

    foreach log_file_line [split $log_file_contents "\n"] {

	# Split each log file line into its pieces
	# 127.0.0.1 - - [22/Jul/2017:07:25:50 +0200] "GET /intranet/index HTTP/1.1" 200 594 ...
	set reg {^([1-9\.]+).+\[(.*)\] \"([^\"]+)\" ([0-9]+) ([0-9]+)}
	if {![regexp $reg $log_file_line match ip date verb_url return_status content_length]} { 
	    ad_return_complaint 1 "Could not parse log line:<br><pre>$log_file_line</pre>"
	}

	if {![regexp {^([A-Z]+) ([^ ]+) ([^ ]+)$} $verb_url match verb url_raw proto]} { 
	    ad_return_complaint 1 "Could not parse verb_url:<br><pre>$verb_url</pre>"
	}

	# Extract the body of the URL
	if {[regexp {^(.+)\?(.*)$} $url_raw match url_path url_params]} {
	    # nada
	} else {
	    set url_path $url_raw
	    set url_params ""
	}
	# ad_return_complaint 1 "<pre>url_raw=$url_raw<br>url_path=$url_path<br>url_params=$url_params</pre>"
	set val ""
	if {[info exists url_hash($url_path)]} { set val $url_hash($url_path) }
	lappend val $return_status
	set url_hash($url_path) $val
    }

}

# ad_return_complaint 1 "<pre>[join [qsort [array names url_hash]] "<br>"]</pre>"


# ---------------------------------------------------------------
# Show index pages pages with visit status information
# ---------------------------------------------------------------

set ctr 0
set index_lines [list]
foreach page $pages {
    # Skip everything that doesn't end with /index
    if {![regexp {/index$} $page]} { continue }

    set page_with_tag [export_vars -base $page {{uid $user_id}}]

    set line "<tr$bgcolor([expr {$ctr % 2}])>\n"
    incr ctr
    append line "<td><nobr><a href=\"$page_with_tag\" target='_'>$page</a></nobr></td>\n"

    set val ""
    if {[info exists url_hash($page)]} { set val $url_hash($page) }
    set count [llength $val]
    if {0 eq $count} { set count "" }
    append line "<td>$val</td>\n"
    append line "</tr>\n"
    
    lappend index_lines $line
}


# ---------------------------------------------------------------
# Show pages with visit status information
# ---------------------------------------------------------------

set ctr 0
set all_lines [list]
foreach page $pages {
    set line "<tr$bgcolor([expr {$ctr % 2}])>\n"
    incr ctr
    append line "<td><nobr><a href=\"$page\" target='_'>$page</a></nobr></td>\n"

    set val ""
    if {[info exists url_hash($page)]} { set val $url_hash($page) }
    set count [llength $val]
    if {0 eq $count} { set count "" }
    append line "<td>$val</td>\n"
    append line "</tr>\n"
    
    lappend all_lines $line
}

