# /www/intranet/companies/accounting-contact-2.tcl
#
# Copyright (C) 2004 ]project-open[
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
    Writes company's accounting contact to the db

    @param company_id company's group id
    @param address_book_id id of the address_book record to set as the accounting contact

    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    company_id:integer,notnull
    user_id:integer,notnull
}

ad_maybe_redirect_for_registration

db_dml companies_set_accounting_contact \
	"update im_companies 
            set accounting_contact_id=:user_id
          where company_id=:company_id" 

db_release_unused_handles

ad_returnredirect view?[export_url_vars company_id]