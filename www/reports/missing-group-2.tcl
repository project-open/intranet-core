# /www/intranet/reports/missing-group-2.tcl
ad_page_contract {
    this is the target for the form in missing-group.tcl  
    it will update the team/group information for the selected users
    we just need to insert a value into user_group_map for each user,team

    @param user

    @author umathur@arsdigita.com on May 4, 2000
    
    @cvs-id missing-group-2.tcl,v 1.4.2.5 2000/08/16 21:25:03 mbryzek Exp
} {
    user:array
    { group_type "" }
}
set user_id [ad_maybe_redirect_for_registration]
set ip_address [ns_conn peeraddr]

foreach user_id_for_group [array names user] {    
    set group_id $user($user_id_for_group)
    if {![string match {no_update} [string trim $group_id]]} {
        ad_user_group_user_add $user_id_for_group "member" $group_id
    }
}
db_release_unused_handles
    
ad_returnredirect missing-group?[export_url_vars group_type]
