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
set attr_value = '/web/$server_name' || substring(attr_value from 'C:/ProjectOpen(.*)')
where attr_value ~* '^C:/ProjectOpen/'
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
