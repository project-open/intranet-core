# /packages/intranet-core/www/admin/user-matrix/toggle.tcl
#
# Copyright (C) 2004 Project/Open 
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
    Add or remove "User Matrix" permissions<br>
    (permissions for members of one group to manage the members
    of another group).

    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    horiz_group_id:integer
    vert_group_id:integer
    action
    { return_url "index"}
}

set current_user_id [ad_maybe_redirect_for_registration]
set current_user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

if {!$current_user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

switch $action {
    add_viewable {
	db_dml grant_permission "
	    begin
	        acs_permission.grant_permission($vert_group_id,$horiz_group_id,'view');
	    end;
	"
    }
    add_readable {
	db_dml grant_permission "
	    begin
	        acs_permission.grant_permission($vert_group_id,$horiz_group_id,'read');
	    end;
	"
    }
    add_writable {
	db_dml grant_permission "
	    begin
	        acs_permission.grant_permission($vert_group_id,$horiz_group_id,'write');
	    end;
	"
    }
    add_administratable {
	db_dml grant_permission "
	    begin
	        acs_permission.grant_permission($vert_group_id,$horiz_group_id,'admin');
	    end;
	"
    }
    remove_viewable {
	db_dml grant_permission "
	    begin
	        acs_permission.revoke_permission($vert_group_id,$horiz_group_id,'view');
	    end;
	"
    }
    remove_readable {
	db_dml grant_permission "
	    begin
	        acs_permission.revoke_permission($vert_group_id,$horiz_group_id,'read');
	    end;
	"
    }
    remove_writable {
	db_dml grant_permission "
	    begin
	        acs_permission.revoke_permission($vert_group_id,$horiz_group_id,'write');
	    end;
	"
    }
    remove_administratable {
	db_dml grant_permission "
	    begin
	        acs_permission.revoke_permission($vert_group_id,$horiz_group_id,'admin');
	    end;
	"
    }
    other {
	ad_return_complaint 1 "Unknown 'action': $action"
	return
    }
}

# Flush the global permissions cache so that the
# new changes become active.
im_permission_flush


ad_returnredirect $return_url
