# /packages/intranet-core/www/users/new-3.tcl
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
    @author unknown@arsdigita.com
    @author frank.bergmann@project-open.com
} {
    user_id:integer,notnull
    email:notnull
    message:notnull
    first_names:notnull
    last_name:notnull
    submit:notnull
}

set current_user_id [ad_maybe_redirect_for_registration]

if {[string equal "Send Email" $submit]} {
    set admin_email [db_string admin_user_email "select email from users where user_id = :current_user_id"]

    ns_sendmail "$email" "$admin_email" "You have been added as a user to [ad_system_name] at [ad_parameter SystemUrl]" "$message"
}

ad_returnredirect /intranet/users

