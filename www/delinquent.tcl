# /www/intranet/delinquent.tcl

ad_page_contract {
    Purpose: Update delinquent file /var/log/delinquent when necessary

    @author jsotil@competitiveness.com
    @creation-date March 2001
    @cvs-id delinquent.tcl,
} {
    user_id
}

set page_title "Remove Delinquent User from List"
set context_bar [ad_context_bar "Delinquent Update"]

set delinquent_user [cl_rm_user_from_delinquent $user_id]


if { $delinquent_user == 1 } {
    append page_body "<b>You have been removed from the delinquent list</b>"
} elseif { $delinquent_user == 0 } {
    append page_body "<b>You cannot be removed from the delinquent list... Log your hours !!!</b>"
} elseif { $delinquent_user == -1 } {
    append page_body "<b>User not found in the delinquent list. May be you have already been removed ?!!</b>"
}

append page_body "<br><hr><h3>REMEMBER: total of 10 units per day! (all the days)</h3>"

doc_return  200 text/html [im_return_template]
