# /www/intranet/companies/accounting-contact-users-2.tcl
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

    @param group_id company's group id
    @param user_id_from_search user we're setting as the accounting contact

    @author various@arsdigita.com
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    group_id:integer
    user_id_from_search
}


ad_maybe_redirect_for_registration


db_dml companies_set_accounting_contact \
	"update im_companies 
            set accounting_contact_id=:user_id_from_search
          where group_id=:group_id" 
db_release_unused_handles


ad_returnredirect view?[export_url_vars group_id]










