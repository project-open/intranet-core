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
    @cvs-id nuke.tcl,v 3.3.6.3.2.3 2000/09/22 01:36:19 kevin Exp
} {
    user_id:integer,notnull
}


db_1row user_full_name "select first_names, last_name
from users
where user_id = :user_id"

db_release_unused_handles

set page_content "[ad_admin_header "Nuke $first_names $last_name"]

<h2>Confirm Nuking $first_names $last_name</h2>

[ad_admin_context_bar [list "index.tcl" "Users"] [list "one.tcl?[export_url_vars user_id]" "One User"] "Nuke user"]

<hr>

Confirm the nuking of <a href=\"one?user_id=$user_id\">$first_names $last_name</a>

<p>

First, unless $first_names $last_name is a test user, you should
probably <a href=\"delete?user_id=$user_id\">delete this user
instead</a>.  Deleting marks the user deleted but leaves intact his or
her contributions to the site content.

<p>

Nuking is a violent irreversible action.  You are instructing the
system to remove the user and any content that he or she has
contributed to the site.  This is generally only appropriate in the
case of test users and, perhaps, dishonest people who've flooded a
site with fake crud.

<P>

<center>
<form method=get action=nuke-2>
<input type=hidden name=user_id value=\"$user_id\">
<input type=submit value=\"Yes, I'm sure that I want to nuke this person\">
</form>
</center>

[ad_admin_footer]
"


doc_return  200 text/html $page_content
