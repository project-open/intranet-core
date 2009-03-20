# /packages/intranet-core/www/admin/cleanup-demo/ltc-convert.tcl
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
    Check that the LTC-Organiser tables are
    present in the curent database

    @author frank.bergmann@project-open.com
} {
    { return_url "" }
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

if {"" == $return_url} { set return_url [ad_conn url] }

set page_title "Confirm LTC-Organiser Import"
set context_bar [im_context_bar $page_title]
set context ""

# ------------------------------------------------------
# Check whether the tables are in place
# ------------------------------------------------------

# Check whether the table "CONTACT" exists.
# im_table_exists doesn't work here, because CONTACT
# is in capital letters from LTC import with DBTools
#
set ltc_data_p [db_string ltc_data "
	select count(*) 
	from pg_class
	where	relname = 'CONTACT' 
		and relname !~ '^pg_'
		and relkind = 'r'
"]




