# /www/admin/users/become.tcl
#

ad_page_contract {
    Location: 42Å∞21'N 71Å∞04'W
    Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
    Purpose:  Let's administrator become any user.

    @param user_id
    @author mobin@mit.edu (Usman Y. Mobin)
    @creation-date Thu Jan 27 04:57:59 EST 2000
    @cvs-id become.tcl,v 3.3.2.4.2.3 2000/07/31 18:50:48 gjin Exp

} {
    user_id:integer,notnull
}


set return_url [ad_pvt_home]

# Get the password and user ID
# as of Oracle 8.1 we'll have upper(email) constrained to be unique
# in the database (could do it now with a trigger but there is really 
# no point since users only come in via this form)

db_0or1row user_password "select password from users where user_id = :user_id"

if { ![info exists password] } {
    ad_return_error "Couldn't find user $user_id" "Couldn't find user $user_id."
    return
}

# just set a session cookie
set expire_state "s"

# note here that we stuff the cookie with the password from Oracle,
# NOT what the user just typed (this is because we want log in to be
# case-sensitive but subsequent comparisons are made on ns_crypt'ed 
# values, where string toupper doesn't make sense)

db_release_unused_handles

ad_user_login $user_id
ad_returnredirect $return_url
#ad_returnredirect "/cookie-chain.tcl?cookie_name=[ns_urlencode ad_auth]&cookie_value=[ad_encode_id $user_id $password]&expire_state=$expire_state&final_page=[ns_urlencode $return_url]"

