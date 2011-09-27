# /packages/intranet-core/www/admin/windows-to-linux.tcl
#
# Copyright (C) 2004 ]project-open[
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
    Convert some parameters values from Windows to Linux
} {
    { server_name "projop" }
    { return_url "/intranet/admin/" }
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

set page_title "Windows - to - Linux"


# ------------------------------------------------------------
# Return the page header.
# This technique allows us to write out HTML output while
# the processes are runnin. Otherwise, the user would
# not see any intermediate results, but only a screen
# after possibly many minutes of waiting...
#

ad_return_top_of_page "[im_header]\n[im_navbar]"
ns_write "<h1>$page_title</h1>\n"
ns_write "<ul>\n"


# Convert all pathes to the Linux style, asuming "$server_name" as the name
# of the server
#
ns_write "<li>Converting pathes from \"C:/ProjectOpen/ to /web/$server_name/\n"
db_dml update_pathes "
	update apm_parameter_values
	set attr_value = '/web/$server_name' || substring(lower(attr_value) from 'c:/projectopen(.*)')
	where attr_value ~* '^c:/projectopen/'
"

db_dml update_pathes "
	update apm_parameter_values
	set attr_value = '/web/$server_name' || substring(lower(attr_value) from 'c:/project-open(.*)')
	where lower(attr_value) ~* '^c:/project-open/'
"

db_dml update "
	update apm_parameter_values
	set attr_value = '/web/$server_name/filestorage/templates'
	where parameter_id in (
		select	parameter_id
		from	apm_parameters
		where	parameter_name = 'InvoiceTemplatePathUnix'
	)
"

db_dml update "
	update apm_parameter_values
	set attr_value = '/var/tmp'
	where parameter_id in (
		select	parameter_id
		from	apm_parameters
		where	parameter_name = 'tmp_path'
	)
"

db_dml update "
	update apm_parameter_values
	set attr_value = '/usr/bin/dot'
	where parameter_id in (
		select	parameter_id
		from	apm_parameters
		where	parameter_name = 'graphviz_dot_path'
	)
"


db_dml update "
	update apm_parameter_values
	set attr_value = '/web/$server_name/filestorage/projects'
	where parameter_id in (
		select	parameter_id
		from	apm_parameters
		where	parameter_name = 'CompanyBasePathUnix'
	)
"

db_dml update "
	update apm_parameter_values
	set attr_value = '/web/$server_name/filestorage/home'
	where parameter_id in (
		select	parameter_id
		from	apm_parameters
		where	parameter_name = 'HomeBasePathUnix'
	)
"

db_dml update "
	update apm_parameter_values
	set attr_value = '/web/$server_name/filestorage/projects'
	where parameter_id in (
		select	parameter_id
		from	apm_parameters
		where	parameter_name = 'ProjectBasePathUnix'
	)
"


db_dml update "
	update apm_parameter_values
	set attr_value = '/web/$server_name/filestorage/tickets'
	where parameter_id in (
		select	parameter_id
		from	apm_parameters
		where	parameter_name = 'TicketBasePathUnix'
	)
"


db_dml update "
	update apm_parameter_values
	set attr_value = '/web/$server_name/filestorage/project_sales'
	where parameter_id in (
		select	parameter_id
		from	apm_parameters
		where	parameter_name = 'ProjectSalesBasePathUnix'
	)
"


db_dml update "
	update apm_parameter_values
	set attr_value = '/web/$server_name/filestorage/users'
	where parameter_id in (
		select	parameter_id
		from	apm_parameters
		where	parameter_name = 'UserBasePathUnix'
	)
"


db_dml update "
	update apm_parameter_values
	set attr_value = '/web/$server_name/filestorage/costs'
	where parameter_id in (
		select	parameter_id
		from	apm_parameters
		where	parameter_name = 'CostBasePathUnix'
	)
"


db_dml update "
	update apm_parameter_values
	set attr_value = '/web/$server_name/filestorage/backup'
	where parameter_id in (
		select	parameter_id
		from	apm_parameters
		where	parameter_name = 'BackupBasePathUnix'
	)
"


db_dml update "
	update apm_parameter_values
	set attr_value = '/web/$server_name/filestorage/bugs'
	where parameter_id in (
		select	parameter_id
		from	apm_parameters
		where	parameter_name = 'BugBasePathUnix'
	)
"



# Convert the find command
ns_write "<li>Converting /bin/find to /usr/bin/find\n"
db_dml update_pathes "
	update apm_parameter_values
	set attr_value = '/usr/bin/find'
	where attr_value = '/bin/find'
"



ns_write "</ul>\n"
ns_write "<p>You can now return to the <a href=$return_url>previous page</a>.</p>"
ns_write [im_footer]
