# /www/intranet/offices/delete-2.tcl
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
    delete the office 
    @param group_id
    @author Tony Tseng <tony@arsdigita.com>
    @creation-date 10/26/00
    @cvs-id delete-2.tcl,v 1.1.2.1 2000/10/30 21:02:30 tony Exp
} {
    office_id:naturalnum
}

#check if the user is an admin
set user_id [ad_verify_and_get_user_id]
if { ![im_is_user_site_wide_or_intranet_admin] } {
    ad_return_forbidden { Access denied } { You must be a site-wide or intranet administrator to delete a office }
    return
}


db_transaction {
    db_dml delete_from_im_house_info {
	delete from im_house_info
	where office_id=:office_id
    }

    db_dml delete_form_im_offices {
	delete from im_offices
	where office_id=:office_id
    }

} on_error {
    ad_return_error "Oracle Error" "Oracle is complaining about this action:\n<pre>\n$errmsg\n</pre>\n"
    return
}


ad_returnredirect "index"

