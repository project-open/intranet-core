ad_page_contract {
    @cvs-id portrait-erase.tcl,v 3.2.2.3.2.3 2000/08/25 23:56:19 minhngo Exp
 
    /admin/users/portrait-erase.tcl

    by philg@mit.edu on September 28, 1999 (his friggin' 36th birthday)

    erase's a user's portrait (NULLs out columns in the database)

    the key here is to null out portrait_upload_date, which is 
    used by pages to determine portrait existence 
} {
    user_id:integer,notnull
} 


ad_maybe_redirect_for_registration

set admin_user_id [ad_verify_and_get_user_id]

if ![im_is_user_site_wide_or_intranet_admin $admin_user_id] {
    ad_return_error "Unauthorized" "You're not a member of the site-wide administration group"
    return
}

db_dml delete_portrait {
   delete from general_portraits
    where on_what_id = :user_id
      and on_which_table = 'USERS'
}]

ad_returnredirect "one?user_id=$user_id"

