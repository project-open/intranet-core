# /packages/intranet-core/www/users/nuke.tcl
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
    Try to remove a user completely

    @author various@arsdigita.com
    @author frank.bergmann@project-open.com
} {
    user_id:integer,notnull
}


db_1row user_full_name "select first_names, last_name
from users
where user_id = :user_id"

db_release_unused_handles

set delete_user_link "<a href=\"delete?user_id=$user_id\">[_ intranet-core.lt_delete_this_user_inst]</a>"

set page_content "[ad_admin_header "[_ intranet-core.lt_Nuke_first_names_last]"]

<h2>[_ intranet-core.lt_Confirm_Nuking_first_]</h2>

[ad_admin_context_bar [list "index.tcl" "[_ intranet-core.Users]"] [list "one.tcl?[export_url_vars user_id]" "[_ intranet-core.One_User]"] "[_ intranet-core.Nuke_user]"]

<hr>

[_ intranet-core.lt_Confirm_the_nuking_of]<a href=\"one?user_id=$user_id\">$first_names $last_name</a>

<p>

[_ intranet-core.lt_First_unless_first_na]

<p>

[_ intranet-core.lt_Nuking_is_a_violent_i]

<P>

<center>
<form method=get action=nuke-2>
<input type=hidden name=user_id value=\"$user_id\">
<input type=submit value=\"[_ intranet-core.lt_Yes_Im_sure_that_I_wa]\">
</form>
</center>

[ad_admin_footer]
"


doc_return  200 text/html $page_content
