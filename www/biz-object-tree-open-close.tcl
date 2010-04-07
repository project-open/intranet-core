# /packages/intranet-core/www/biz-object-tree-open-close.tcl
#
# Copyright (c) 2009 ]project-open[
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
    Open/Close the branches of a business object tree.
    @param object_id	The object to open/close
    @param page_url	The name of the page. "default" is default.
    @param user_id	The user for whom to open/close the tree
    @param return_url	Where to return
    @param open_p	"o" or "c".

    @author frank.bergmann@project-open.com
} {
    object_id:integer,multiple
    return_url
    { page_url "default" }
    { user_id "" }
    { open_p "o" }
}


# --------------------------------------------------------------
# Permissions
# --------------------------------------------------------------

set current_user_id [ad_get_user_id]
if {"" == $user_id} { set user_id $current_user_id }
if {$user_id != $current_user_id} { ad_returnredirect $return_url }


# -----------------------------------------------------------
# Set the status
# -----------------------------------------------------------

# Assume that there are few entries in the list of closed tree objects.

foreach oid $object_id {
    if {[catch {
	db_dml insert_tree_status "
	insert into im_biz_object_tree_status (
		object_id,
		user_id,
		page_url,
		open_p,
		last_modified
	) values (
		:oid,
		:user_id,
		:page_url,
		:open_p,
		now()
	)
        "
    } err_msg]} {
	# There was probably already an entry, so update the entry.
	db_dml update_tree_status "
	update	im_biz_object_tree_status
	set	open_p = :open_p,
		last_modified = now()
	where	object_id = :oid and
		user_id = :user_id and
		page_url = :page_url
        "
    }
}

ad_returnredirect $return_url


