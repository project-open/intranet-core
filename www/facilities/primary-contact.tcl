# /www/intranet/facilities/primary-contact.tcl
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
    Allows user to choose primary contact for office
    @param limit_to_users_in_group_id:integer
    @param office_id:integer
   
    @author: Mike Bryzek (mbrysek@arsdigita.com)
    @creation-date Jan 2000
    @cvs-id primary-contact.tcl,v 1.5.2.15 2000/09/22 01:38:36 kevin Exp
} {
    limit_to_users_in_group_id:integer,optional
    office_id:integer
}

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

# Avoid hardcoding the url stub
set target [ns_conn url]
regsub {primary-contact} $target {primary-contact-2} target



set office_name [db_string office_name \
	"select office_name from im_offices where office_id = :office_id"]

db_release_unused_handles

set page_title "Select primary contact for $office_name"
set context_bar [ad_context_bar [list ./ "Offices"] [list view?[export_url_vars office_id] "One office"] "Select contact"]

set page_body "

Locate your new primary contact by

<form method=get action=/user-search>
[export_form_vars office_id target limit_to_group_id]
<input type=hidden name=passthrough value=office_id>

<table border=0>
<tr><td>Email address:<td><input type=text name=email size=40></tr>
<tr><td colspan=2>or by</tr>
<tr><td>Last name:<td><input type=text name=last_name size=40></tr>
</table>

<p>

<center>
<input type=submit value=Search>
</center>
</form>

"

doc_return  200 text/html [im_return_template]

