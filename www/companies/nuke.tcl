# /packages/intranet-core/www/companies/nuke.tcl
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
    company_id:integer,notnull
    { return_url "/intranet/users" }
}


db_1row full_name "
	select	*
	from	im_companies
	where	company_id = :company_id
"

set page_title [lang::message::lookup "" intranet-core.Nuke_this_company "Nuke this company"]
set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-core.Projects]"] $page_title]
set object_name $company_name
set object_type "company"

