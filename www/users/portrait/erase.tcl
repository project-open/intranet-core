# /packages/intranet-core/www/users/portraits/erase.tcl
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
    ask user whether they're sure they want to erase their portrait

    @cvs-id erase.tcl,v 1.1.2.4 2000/09/22 01:36:30 kevin Exp
    @param user_id
} {
    user_id:naturalnum,notnull
}

set page_title "Erase Portrait"
set context_bar [ad_context_bar [list "index.tcl" "Your Portrait"] "Erase"]

set page_body "
Are you sure that you want to erase your portrait?

<center>
<form method=POST action=\"erase-2\">
[export_form_vars user_id]
<input type=submit value=\"Yes, I'm sure\">
</form>
</center>
"

db_release_unused_handles
doc_return  200 text/html [im_return_template]
