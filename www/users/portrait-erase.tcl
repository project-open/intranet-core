# /packages/intranet-core/www/users/portrait-erase.tcl
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
    erase's a user's portrait (NULLs out columns in the database)
    the key here is to null out portrait_upload_date, which is 
    used by pages to determine portrait existence 

    @author philg@mit.edu 
    @creation_date September 28, 1999 (his friggin' 36th birthday)
} {
    user_id:integer,notnull
} 


ad_maybe_redirect_for_registration

set admin_user_id [ad_verify_and_get_user_id]

if ![im_is_user_site_wide_or_intranet_admin $admin_user_id] {
    ad_return_error "Unauthorized" "You're not a member of the site-wide administration group"
    return
}

db_dml delete_portrait {
   delete from general_portraits
    where on_what_id = :user_id
      and on_which_table = 'USERS'
}]

ad_returnredirect "one?user_id=$user_id"

