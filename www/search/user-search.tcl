# /packages/intranet-core/www/user-search.tcl
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
    Purpose: Standard form to search for a user (through /user-search.tcl)

    @param target Where to link to.
    @param passthrough What to pass on.

    @author mbryzek@arsdigita.com
    @author frank.bergmann@project-open.com
} {
    target:optional
    passthrough:optional    
    keyword:optional
}

set user_id [ad_maybe_redirect_for_registration]

set page_title "[_ intranet-core.Search_for_a_user]"
set context_bar [im_context_bar [list ./ "[_ intranet-core.Intranet]"] "[_ intranet-core.User_search]"]

#jruiz 20020610: select user
if { [info exist keyword] && ![empty_string_p $keyword]} {
    set sql_keyword "%[string tolower $keyword]%"
    set query "select \
	         user_id as user_id_from_search, \
		 first_names as first_names_from_search, \
		 last_name as last_name_from_search, \
		 email as email_from_search, user_state \
		 from users \
               where (lower(email) like :sql_keyword or lower(first_names || ' ' || last_name) like :sql_keyword) \
	       and user_state = 'authorized'"
    set page_body "Users: <ul>"
    db_foreach user_search_admin $query {
	append page_body "<li><a href=\"/shared/community-member?user_id=$user_id_from_search\"> $first_names_from_search $last_name_from_search ($email_from_search)</a>\n"
    }
    append page_body "</ul>"
} else {

    set page_body "

    [_ intranet-core.Locate_user_by]:

    <form method=get action=/user-search>
    [export_ns_set_vars form]

    <table border=0>
    <tr><td>[_ intranet-core.Email_address]:<td><input type=text name=email size=40></tr>
    <tr><td colspan=2>or by</tr>
    <tr><td>[_ intranet-core.Last_name]:<td><input type=text name=last_name size=40></tr>
    </table>
    
    <p>
    
    <center>
    <input type=submit value=\"[_ intranet-core.Search]\">
    </center>
    </form>
    "
}

ad_return_template



