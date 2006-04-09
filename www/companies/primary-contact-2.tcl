# /www/intranet/companies/primary-contact-2.tcl
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
    Writes company's primary contact to the db

    @param company_id company's group id

    @author unknown@arsdigita.com
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    company_id:integer,notnull
    user_id:integer,notnull
}

ad_maybe_redirect_for_registration

db_dml companies_set_primary_contact "
update 
	im_companies 
set
	primary_contact_id=:user_id
where
	company_id=:company_id" 

db_release_unused_handles

ad_returnredirect view?[export_url_vars company_id]