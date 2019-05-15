# /packages/sencha-rest/www/login.tcl
#
# Copyright (C) 2013 ]project-open[

ad_page_contract {
    Provide the user with cookies and a login token
    @author frank.bergmann@project-open.com

    @param node Passed by ExtJS to load sub-trees of a tree.
                Normally not used, just in case of error.
} {
    {email ""}
    {password ""}
    {expiry_date ""}
}


if {"" == $password || "" == $email} {
    doc_return 200 "text/json" "FAIL - no email or password"
    ad_script_abort
}

array set result_array [auth::authenticate \
			    -email $email \
			    -password $password \
			    -persistent  \
]

set account_status "undefined"
set user_id 0
if {[info exists result_array(account_status)]} { set account_status $result_array(account_status) }
if {[info exists result_array(user_id)]} { set user_id $result_array(user_id) }

if {"ok" == $account_status && 0 != $user_id} { 
    ad_user_login -forever=0 $user_id
    set token [im_generate_auto_login -user_id $user_id -expiry_date $expiry_date]
    doc_return 200 "text/json" "{\"success\": true, \"message\": \"success\", \"token\": \"$token\"}"
    ad_script_abort
} else {
    set auth_message $result_array(auth_message)
    doc_return 401 "text/json" "{\"success\": false, \"message\": \"$auth_message\"}"
    ad_script_abort
}

