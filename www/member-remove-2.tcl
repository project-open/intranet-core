# /packages/intranet-core/www/member-remove-2.tcl
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
    
    Replicates functionality of /www/groups/member-remove-2.tcl but is
    less stringent on permissions (i.e. any member of a group can remove
    anyone else in that group).

    @param group_id
    @param user_id
    @param return_url:optional
    
    @author Mike Bryzek (mbryzek@arsdigita.com)
    @creation-date 4/4/2000
    @cvs-id member-remove-2.tcl,v 3.4.6.7 2000/08/16 21:24:30 mbryzek Exp
} {
    group_id:integer,notnull
    user_id:integer,notnull
    return_url:optional
}


set mapping_user [ad_verify_and_get_user_id]



if { ![im_can_user_administer_group $group_id $mapping_user] } {
    ad_return_complaint 1 "<li>Permission Denied<br>You do not have permission to remove a member from this group."
    return
}

db_dml delete_user_from_group \
	"delete from user_group_map 
          where user_id = :user_id 
            and group_id = :group_id"

db_release_unused_handles

if { [exists_and_not_null return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect "index"
}

