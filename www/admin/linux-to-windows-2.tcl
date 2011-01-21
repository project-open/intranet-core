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
    { install_dir "c:/project-open" }
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

set page_title "Linux - to - Windows"


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


# Convert all pathes to the Linux style, asuming "$install_dir" as the name
# of the server
#
ns_write "<li>Converting pathes from /web/&lt;server&gt;/ to \"$install_dir/ \n"
db_dml update_pathes "
	update apm_parameter_values
	set attr_value = '$install_dir/' || substring(attr_value from '^/web/\[a-zA-Z\]+/(.*)')
	where attr_value ~* '^/web/\[a-zA-Z\]+/'
"


# Convert the find command
ns_write "<li>Set the find command from /usr/bin/find to /bin/find\n"
parameter::set_from_package_key -package_key "intranet-core" -parameter "FindCmd" -value "/bin/find"


# Set pathes for binaries
set dot_path "./bin/dot.bat"
ns_write "<li>Set pathes for acs-workflow graphwiz_dot_path the windows dot.bat wrapper"
parameter::set_from_package_key -package_key "acs-workflow" -parameter "graphviz_dot_path" -value $dot_path

set tmp_path "./servers/projop/tmp"
ns_write "<li>Set pathes for acs-workflow tmp_path to a suitable Windows value: '$tmp_path'"
parameter::set_from_package_key -package_key "acs-workflow" -parameter "tmp_path" -value $tmp_path

set pathes {
    { intranet-core		BackupBasePathUnix		./servers/projop/filestorage/backup		}
    { intranet-filestorage	HomeBasePathUnix		./servers/projop/filestorage/home		}
    { intranet-filestorage	ProjectSalesBasePathUnix	./servers/projop/filestorage/project_sales	}
    { intranet-filestorage	UserBasePathUnix  		./servers/projop/filestorage/users		}
    { intranet-filestorage	BugBasePathUnix			./servers/projop/filestorage/bugs		}
    { intranet-filestorage	CompanyBasePathUnix		./servers/projop/filestorage/projects		}
    { intranet-filestorage	ProjectBasePathUnix		./servers/projop/filestorage/projects		}
    { intranet-filestorage	TicketBasePathUnix		./servers/projop/filestorage/tickets		}
    { intranet-invoices		InvoiceTemplatePathUnix		./servers/projop/filestorage/templates		}
}

foreach tuple $pathes {
    set package [lindex $tuple 0]
    set param [lindex $tuple 1]
    set base_path [lindex $tuple 2]
    ns_write "<li>Set path for intranet-filestorage $param to: '$base_path'"
    parameter::set_from_package_key -package_key $package -parameter $param -value $base_path
}


ns_write "</ul>\n"
ns_write "<p>You can now return to the <a href=$return_url>previous page</a>.</p>"
ns_write [im_footer]
