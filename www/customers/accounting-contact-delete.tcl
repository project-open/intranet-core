# /www/intranet/customers/accounting-contact-delete.tcl
#
# Copyright (C) 2004 Project/Open
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
    Removes customer's accounting contact

    @param group_id customer's group id
    @param return_url where to go once we're done

    @author Frank Bergmann (fraber@fraber.de)

} {
    group_id:integer
    return_url
}

ad_maybe_redirect_for_registration

db_dml customers_delete_accounting_contact \
	"update im_customers
            set accounting_contact_id=null
          where group_id=:group_id" 

db_release_unused_handles

ad_returnredirect $return_url
