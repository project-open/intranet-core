# /www/intranet/companies/accounting-contact-delete.tcl
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
    Removes company's accounting contact

    @param company_id company's group id
    @param return_url where to go once we're done

    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    company_id:integer
    return_url
}

ad_maybe_redirect_for_registration

db_dml companies_delete_accounting_contact \
	"update im_companies
            set accounting_contact_id=null
          where company_id=:company_id" 

db_release_unused_handles

ad_returnredirect $return_url
