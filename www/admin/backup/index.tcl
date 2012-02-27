# /packages/intranet-core/www/admin/menus/index.tcl
#
# Copyright (C) 2004 ]project-open[
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
    Show the permissions for all menus in the system

    @author frank.bergmann@project-open.com
} {
    { return_url "/intranet/admin/backup/index" }

    item_remove:optional
    filename:multiple,optional
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set page_title "Backup & Restore"
set context_bar [im_context_bar $page_title]
set context ""
set find_cmd [parameter::get -package_id [im_package_core_id] -parameter "FindCmd" -default "/bin/find"]

set menu_url "/intranet/admin/menus/new"
set toggle_url "/intranet/admin/toggle"
set group_url "/admin/groups/one"

set bgcolor(0) " class=rowodd"
set bgcolor(1) " class=roweven"

# ------------------------------------------------------
# Get the list of backup sets for restore
# ------------------------------------------------------

# Get the list of all backup sets under backup_path
set backup_path [im_backup_path]
set backup_path_exists_p [file exists $backup_path]
set not_backup_path_exists_p [expr !$backup_path_exists_p]
set file_body ""

multirow create backup_files filename file_body extension date size

foreach file [lsort [glob -nocomplain -type f -directory $backup_path "pg_dump.*.{sql,pgdmp,gz,bz2}"]]  {
    set trim [string range $file [string length $backup_path] end]

    if {[regexp {(\d\d\d\d)(\d\d)(\d\d)\.(\d\d)(\d\d)\d\d\.([0-9a-z\.]+)$} $trim match file_year file_month file_day file_hour file_second file_extension]} {

	# Get rid of the leading "/" of $match
	if {[regexp {^\/(.*)} $trim match body]} { set file_body $body }
	if { ""==$file_body } { set file_body $file }

	multirow append backup_files \
	    $file \
	    $file_body \
	    $file_extension \
	    "$file_day.$file_month.$file_year $file_hour:$file_second" \
	    [file size $file] 
    }
}

set actions [list \
	"New backup" [export_vars -base pg_dump] "Create new postgres dump" \
	"Upload dump" [export_vars -base upload-pgdump] "Upload an existing dump" \
	"Reinstall TSearch2 Search Engine" [export_vars -base reinstall-tsearch2] "reinstall the TSearch2 Search engine" \
]

set bulk_actions [list \
	"Delete" "delete-pgdump" "Remove checked dumps" \
	"Bzip" "bzip-pgdump" "Compress the dump bzip2" \
	"Un-Bzip" "unbzip-pgdump" "Uncompress the dump" \
]


template::list::create \
    -name backup_files \
    -key filename \
    -elements {
	filename {
	    label "file name"
            link_url_eval "/intranet/admin/backup/download/$file_body"
	}
	extension {
	    label "type"
	}
	date {
	    label "date"
	}
	size {
	    label "size"
	    html { align right }
	}
	remove {
	    display_template {<a class=button href="restore-pgdmp?filename=@backup_files.filename@&return_url=$return_url">restore</a>}
	}
    } \
    -bulk_actions $bulk_actions \
    -bulk_action_method post \
    -bulk_action_export_vars { return_url } \
    -actions $actions

