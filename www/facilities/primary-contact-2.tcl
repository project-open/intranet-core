# /www/intranet/facilities/primary-contact-2.tcl
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
    Stores primary contact id for the office
    @param office_id:integer,notnull
    @param user_id_from_search:integer,notnull

    @author Mike Bryzek (mbryzek@arsdigita.com)
    @creation-date Jan 2000
    @cvs-id primary-contact-2.tcl,v 1.3.2.7 2000/08/16 21:24:52 mbryzek Exp
} {
    
    user_id_from_search:integer,notnull
    office_id:integer,notnull
}
set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration


db_dml update_office \
	"update im_offices 
            set contact_person_id=:user_id_from_search
          where office_id=:office_id" 

db_release_unused_handles

ad_returnredirect view?[export_url_vars office_id]


