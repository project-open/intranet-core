ad_page_contract {
    erase's a user's portrait (NULLs out columns in the database)

    the key here is to null out live_revision, which is 
    used by pages to determine portrait existence

    @cvs-id $Id$
} {
    user_id
    return_url
}

set current_user_id [ad_maybe_redirect_for_registration]

# Check the permissions that the current_user has on user_id
im_user_permissions $current_user_id $user_id view read write admin

if {!$write} {
    ad_return_complaint 1 "<li>You have insufficient permissions to erase a portrait for this user."
    return
}


# ---------- Determine the location of the portrait file -----------
set base_path [im_filestorage_user_path $user_id]
if {"" == $base_path} {
    ad_return_complaint 1 "<LI>Unknown folder."
    return
}

# --------------- Delete portraits from FS --------------------

set find_cmd [im_filestorage_find_cmd]
set dest_path "$base_path/"

if { [catch {
    ns_log Notice "portraits/erase-2: $find_cmd $dest_path -type f -maxdepth 1 -name 'portrait.*'"
    set file_list [exec $find_cmd $dest_path -type f -maxdepth 1]
    ns_log Notice "portraits/erase-2: file_list=$file_list"

    foreach file $file_list {
	if {[regexp {portrait} $file match]} {
	    ns_log Notice "portraits/erase-2: /bin/rm $file"
	    exec /bin/rm $file
	}
    }
    
} err_msg] } {
    ad_return_complaint 1 "<b>Error deleting portrait file</b>:<br><pre>$err_msg</pre>"
    return
}


# --------------- Remove from persons table --------------------

db_dml person_portrait_delete "
	update persons
		set portrait_file = NULL
	where
		person_id = :user_id
"


# --------------- Delete portraits from Content Repository (if still there) --------------------

db_dml portrait_delete "
	update cr_items
	   set live_revision = NULL
	where item_id = (
	   select object_id_two
	   from acs_rels
	   where object_id_one = :user_id
	   and rel_type = 'user_portrait_rel'
	)
"


ad_returnredirect $return_url
