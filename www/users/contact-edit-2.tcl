# /packages/intranet-core/www/users/contact-edit-2.tcl
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
    @author unknown@arsdigita.com
    @author Guillermo Belcic (guillermo.belcic@project-open.com)
} {
    user_id:integer,notnull
    { update_note "" }
    { notes "" }
}

# user_id and everything in user_contract
# to do: this page will probably break!!!  what are the form vars?

set num_rows [db_string user_contact_list_size "select count(user_id)
from users_contact where user_id = :user_id"]
ns_set delkey [ns_getform] submit
if {$num_rows == 0} {
    set statement_name "contact_insert"
    set sql_statement_and_bind_vars [util_prepare_insert users_contact [ns_getform]]
} else {
    set statement_name "contact_update"
    set sql_statement_and_bind_vars [util_prepare_update users_contact user_id $user_id [ns_getform]]
}
set sql_statement [lindex $sql_statement_and_bind_vars 0]
set bind_vars [lindex $sql_statement_and_bind_vars 1]
db_dml $statement_name $sql_statement -bind $bind_vars
if {$num_rows > 0 && [string equal "Update" $update_note]} {
    db_dml update_notes "
	update
		users_contact
	set
		note = $notes
	where
		user_id = :user_id
"}
db_release_unused_handles
ad_returnredirect "/intranet/users/view.tcl?[export_url_vars user_id]"








