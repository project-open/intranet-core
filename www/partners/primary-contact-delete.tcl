# /www/intranet/partners/primary-contact-delete.tcl
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
    Removes partner's primary contact

    @param group_id 
    @param return_url 

    @author mbryzek@arsdigita.com
    @creation-date 4/5/2000

    @cvs-id primary-contact-delete.tcl,v 3.3.2.5 2000/08/16 21:24:57 mbryzek Exp
} {
    group_id:integer
    return_url
}

ad_maybe_redirect_for_registration




db_dml update_partner_to_null \
	"update im_partners
            set primary_contact_id=null
          where group_id=:group_id"

db_release_unused_handles


ad_returnredirect $return_url