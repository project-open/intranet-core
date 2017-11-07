ad_page_contract {
    user-skin-info.tcl
    @author iuri sampaio(iuri.sampaio@gmail.com)
    @date 1020-10-29
} 
if {$user_id} {set user_id_from_search $user_id}
if {0 == $user_id} {
    # The "Unregistered Vistior" user
    # Just continue and show his data...
}

set current_user_id [auth::require_login]
set current_url [im_url_with_query]

# Check the permissions 
im_user_permissions $current_user_id $user_id_from_search view read write admin

# ToDo: Cleanup component to use $write instead of $edit_user
set edit_user $write

if {!$read} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient]"
    return
}

# ---------------------------------------------------------------
# Get everything about the user
# ---------------------------------------------------------------
set date_format "YYYY-MM-DD"

set result [db_0or1row users_info_query {}]
if {"" eq $member_state} { set member_state "undefined" }

if { $result > 1 } {
    ad_return_complaint "[_ intranet-core.Bad_User]" "
    <li>There is more then one user with the ID $user_id_from_search"
    return
}


# ---------------------------------------------------------------
# Administration
# ---------------------------------------------------------------

if { [info exists registration_ip] && $registration_ip ne "" } {
    set registration_ip_link "<a href=/intranet/admin/host?ip=[ns_urlencode $registration_ip]>$registration_ip</a>"
}

set user_id $user_id_from_search

# Return a pretty member state (no normal user understands "banned"...)
case $member_state {
	"banned" { set user_state [lang::message::lookup "" intranet-core.Member_state_deleted "deleted"] }
	"approved" { set user_state [lang::message::lookup "" intranet-core.Member_state_active "active"] }
	default { set user_state $member_state }
}

set activate_delete_link ""
if {$admin} {
    append activate_delete_link "("

set member_state xxxx
    switch $member_state {
	"approved" {
	    append activate_delete_link "<a href=/intranet/users/member-state-change?member_state=banned&[export_vars {user_id return_url}]>[_ intranet-core.delete]</a>"	
	}
	"banned" {
	    append activate_delete_link "<a href=/acs-admin/users/member-state-change?member_state=approved&[export_vars {user_id return_url}]>[_ intranet-core.activate]</a>"
	} 
	default {
	    append activate_delete_link "<a href=[export_vars -base "/intranet/users/nuke" {user_id return_url}]>[lang::message::lookup "" intranet-core.nuke Nuke]</a>"
	}

    }

    append activate_delete_link ")"
}

set change_pwd_url [export_vars -base /intranet/users/password-update {user_id return_url}]
set new_company_from_user_url [export_vars -base "/intranet/companies/new-company-from-user" {{user_id $user_id_from_search}}]


# Check if there is a OTP (one time password) module installed
set otp_installed_p [util_memoize [list db_string otp_installed {} -default 0]]

if {$otp_installed_p} {
    set list_otp_pwd_base_url "/intranet-otp/list-otps"
    set list_otp_pwd_url [export_vars -base $list_otp_pwd_base_url {user_id {return_url $current_url}}]
}

set add_companies_p [im_permission $current_user_id add_companies]

set date_created [db_string get_date_created {}]
