# /www/intranet/companies/accounting-contact-users.tcl
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
    Allows you to have a accounting contact that references the users
    table. We don't use this yet, but it will indeed be good once all
    companies are in the users table

    @param group_id group id of the company

    @author mbryzek@arsdigita.com
    @author frank.bergmann@project-open.com
} {
    group_id:integer
    
}

set user_id [ad_maybe_redirect_for_registration]

# Avoid hardcoding the url stub
set target "[im_url_stub]/companies/accounting-contact-users-2"

set company_name [db_string company_name \
	"select g.group_name
           from im_companies c, user_groups g
          where c.group_id = :group_id
            and c.group_id=g.group_id"]

db_release_unused_handles

set page_title "[_ intranet-core.lt_Select_accounting_con]"
set context_bar [im_context_bar [list ./ "[_ intranet-core.Companies]"] [list view?[export_url_vars group_id] "[_ intranet-core.One_company]"] "[_ intranet-core.Select_contact]"]

set page_body "

[_ intranet-core.lt_Locate_your_new_accou]

<form method=get action=/user-search>
[export_form_vars group_id target limit_to_users_in_group_id]
<input type=hidden name=passthrough value=group_id>

<table border=0>
<tr><td>[_ intranet-core.Email_address]:<td><input type=text name=email size=40></tr>
<tr><td colspan=2>[_ intranet-core.or_by]</tr>
<tr><td>[_ intranet-core.Last_name]:<td><input type=text name=last_name size=40></tr>
</table>

<p>

<center>
<input type=submit value='[_ intranet-core.Search]'>
</center>
</form>

"
ad_return_template