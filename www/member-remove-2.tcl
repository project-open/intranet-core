# /www/intranet/member-remove-2.tcl

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
    ad_return_error "Permission Denied" "You do not have permission to remove a member from this group."
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

