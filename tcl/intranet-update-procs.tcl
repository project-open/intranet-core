# /packages/intranet-core/tcl/intranet-update-procs.tcl
#
# Copyright (c) 2008 ]project-open[
# All rights reserved.
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

ad_library {
    Update procedures to deal with issues of APM upgrade.

    @author frank.bergmann@project-open.com
}

ad_proc -public im_update_package {
    { -package_key "" }
} {
    Run all update scripts of a specific package
} {
    set path "[acs_root_dir]/packages/$package_key"
    set find_cmd [im_filestorage_find_cmd]

    if {[catch {
        set file_list [exec $find_cmd $path -type f]
    } err_msg]} {
	ad_return_complaint 1 "Error executing 'exec find $path -name '*.sql'':<br>
        <pre>$err_msg</pre>"
	ad_script_abort
    }

    set sql_files [list]
    foreach file $file_list {
	if {![regexp {\.sql$} $file match]} { continue }
	if {![regexp {/upgrade/upgrade} $file match]} { continue }
	if {![regexp {/intranet\-} $file match]} { continue }
	if {![regexp {postgresql} $file match]} { continue }
	if {[regexp {CVS} $file match]} { continue }

	set key ""
	if {[regexp {(upgrade-.*\.sql)} $file match key]} {
	    lappend sql_files [list $file $key]
	}
    }

    set sorted_sql_files [qsort $sql_files [lambda {s} { lindex $s 1 }]]

    ad_return_complaint 1 $sorted_sql_files

    set file "[acs_root_dir]/packages/intranet-core/sql/postgresql/upgrade/upgrade-3.4.0.0.0-3.4.0.1.0.sql"
    db_source_sql_file $file
}
