# /www/intranet/facilities/index.tcl
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
    Lists all offices
   
    @author Mark C (markc@arsdigita.com)
    @creation-date May 2000
    @cvs-id index.tcl,v 1.4.2.8 2000/09/22 01:38:36 kevin Exp
} {
}
    
set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set results ""
db_foreach office_selected "select office_id, office_name 
                              from im_offices 
                              order by office_name" {
    if { [empty_string_p $results] } {
        set results "<ul>"
    }
    append results "  <li> <a href=view?[export_url_vars office_id]>$office_name</a>\n"
			      
} 

if { [empty_string_p $results] } {
    set results "  <p><b> There are no offices </b>\n" 
} else {
    append results "</ul>\n"
}

db_release_unused_handles

set page_title "Offices"
set context_bar [ad_context_bar $page_title]

set page_body "
$results
<ul>
<li><a href=ae>Add a office</a>
</ul>
"

append page_body "</ul>\n"

doc_return  200 text/html [im_return_template]

