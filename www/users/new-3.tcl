ad_page_contract {
    @cvs-id user-add-3.tcl,v 3.4.2.3.2.3 2000/09/22 01:36:24 kevin Exp
} {
    user_id:integer,notnull
    email:notnull
    message:notnull
    first_names:notnull
    last_name:notnull
    submit:notnull
}

set current_user_id [ad_maybe_redirect_for_registration]

if {[string equal "Send Email" $submit]} {
    set admin_email [db_string admin_user_email "select email from users where user_id = :current_user_id"]

    ns_sendmail "$email" "$admin_email" "You have been added as a user to [ad_system_name] at [ad_parameter SystemUrl]" "$message"
}

ad_returnredirect /intranet/users

