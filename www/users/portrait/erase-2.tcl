# /packages/intranet-core/www/users/portraits/erase-2.tcl
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
    erase a user's portrait (NULLs out columns in the database)

    the key here is to null out portrait_upload_date, which is used by
    pages to determine portrait existence

    @cvs-id erase-2.tcl,v 1.1.2.3 2000/08/25 23:56:49 minhngo Exp
    @author philg@mit.edu

    @param user_id
} {
    user_id:naturalnum,notnull
    { return_url ""}
}

ad_maybe_redirect_for_registration

db_dml erase_portrait {
   delete from general_portraits
    where on_what_id = :user_id
      and upper(on_which_table) = 'USERS'
}

if {"" == $return_url} {
    set return_url "/intranet/users/view?[export_url_vars user_id]"
}

ad_returnredirect $return_url
