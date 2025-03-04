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

    Multiple object_ids can be passed also as a comma separated value 
    This is required when a XHR post is made and duplicate keys are not supported  
    return_url and object_id needs to be empty in this case. 

    @param object_id	The object to open/close
    @param page_url		The name of the page. "default" is default.
    @param user_id		The user for whom to open/close the tree
    @param return_url	Where to return
    @param open_p		"o" or "c".
    @param object_ids	object_id's, comma separated object_i's 
    
    @author frank.bergmann@project-open.com
} {
    { object_id:integer,multiple "" }
    { return_url "" }
    { page_url "default" }
    { user_id:integer "" }
    { open_p "" }
    { object_ids "" }
}

# --------------------------------------------------------------
# Check security and allow "root" as object_id
# --------------------------------------------------------------

if {"root" eq $object_id} { set object_id "0"}
if {[im_security_alert_check_integer -location "biz-object-tree-open-close.tcl" -value $object_id -severity "Normal"]} { set object_id "0" }


# --------------------------------------------------------------
# Permissions
# --------------------------------------------------------------

set current_user_id [ad_conn user_id]
if {"" == $user_id} { set user_id $current_user_id }
if {$user_id != $current_user_id} { ad_returnredirect $return_url }


# -----------------------------------------------------------
# Set the status
# -----------------------------------------------------------

if {"" eq $object_id } {
    set object_id [split $object_ids ","]
}

# Assume that there are few entries in the list of closed tree objects.
foreach oid $object_id {

    if {"root" eq $oid} { continue }
    if {[im_security_alert_check_integer -location "biz-object-tree-open-close.tcl" -value $oid]} { continue }

    db_1row info "
	select	(select	count(*)
		from	acs_objects
		where	object_id = :oid
		) as oid_exists_p,
		(select	count(*)
		from	im_biz_object_tree_status
		where	object_id = :oid and 
			user_id = :user_id and 
			page_url = :page_url
		) as status_exists_p
	from	dual
    "

    # Skip of the object dosn't exist. This may happen with partically saved GanttEditor trees
    if {!$oid_exists_p} { continue }

    if {!$status_exists_p} {
	db_dml insert_tree_status "
		insert into im_biz_object_tree_status (object_id, user_id, page_url, open_p, last_modified) 
		values (:oid, :user_id, :page_url, :open_p, now())
	"
    } else {
	# There is already an entry
	db_dml update_tree_status "
		update	im_biz_object_tree_status
		set	open_p = :open_p,
			last_modified = now()
		where	object_id = :oid and user_id = :user_id and page_url = :page_url
        "
    }
}
if { "" == $return_url } {
    ns_return 200 text/html "\{\"success\": true, \"total\": 0, \"message\": \"\", \"data\": \[\{\}\]\}"
} else {
    ad_returnredirect $return_url
}



