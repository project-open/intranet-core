# /www/admin/users/freelance-info-update-2.tcl
#

ad_page_contract {
    @param user_id
    @author Guillermo Belcic
    @creation-date 10-13-2003
    @cvs-id freelance-info-update-2.tcl,v 3.2.2.4.2.6 2000/09/12 20:11:22 cnk Exp
} {
    user_id:integer,notnull
    { web_site "" }
    { translation_rate "" }
    { editing_rate "" }
    { hourly_rate "" }
    { bank_account "" }
    { bank "" }
    { payment_method "" }
    { note "" }
    { private_note "" }
    { cv "" }
    { return_url "" }
}

#--------------------------------------------------------------------
# Security and Defaults
#--------------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_employee_p [im_user_is_employee_p $current_user_id]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
set yourself_p [expr $user_id == $current_user_id]

if {!$yourself_p && !$user_is_employee_p && !$user_admin_p} {
    ad_return_complaint "Insufficient Privileges" "<li>You have insufficient privileges to modify user $user_id\
."
    return
}

if {[string equal "" $return_url]} {
    set return_url "/intranet/users/view?user_id=$user_id"
}

#--------------------------------------------------------------------
# Update the base data
#--------------------------------------------------------------------

if [catch {
db_dml sql "
UPDATE
	im_freelancers
SET
	web_site = :web_site,
    	translation_rate = :translation_rate,
    	editing_rate = :editing_rate,
    	hourly_rate = :hourly_rate,
    	bank_account = :bank_account,
    	bank = :bank,
	payment_method_id = :payment_method,
    	note = :note,
	private_note = :private_note,
    	cv = :cv
WHERE
	user_id = :user_id"
} errmsg ] {
     ad_return_complaint "Argument Error" "<ul>$errmsg</ul>"
    return
}

db_release_unused_handles
ad_returnredirect $return_url
