ad_page_contract {
    @param user_id
    @param banned_p
    @param banning_note
    @param return_url
    @author ?
    @creation-date ?
    @cvs-id delete-2.tcl,v 3.2.2.3.2.4 2000/09/22 01:36:17 kevin Exp
} {
    user_id:integer,notnull
    banned_p:optional
    banning_note:optional
    return_url:optional
}



set admin_user_id [ad_verify_and_get_user_id]

if { $admin_user_id == 0 } {
    ad_returnredirect /register.tcl?return_url=[ns_urlencode "/admin/users/"]
    return
}



set user_name [db_string user_full_name "select first_names || ' ' || last_name from users where user_id = :user_id"]

if { [info exists banned_p] && $banned_p == "t" } {
    db_dml ban_user "update users 
set banning_user = :admin_user_id,
    banned_date = sysdate,
    banning_note = :banning_note,
    user_state = 'banned'
where user_id = :user_id"
    set action_report "has been banned."
} else {
    db_dml delete_user "update users set deleted_date=sysdate,
deleting_user = :admin_user_id,
user_state = 'deleted'
where user_id = :user_id"
    set action_report "has been marked \"deleted\"."
}

if { [exists_and_not_null return_url] } {
    ad_returnredirect $return_url
    return
}

doc_return  200 text/html "[ad_admin_header "Account deleted"]

<h2>Account Deleted</h2>

<hr>

$user_name $action_report.

[ad_admin_footer]
"
