# /www/intranet/offices/delete-2.tcl

ad_page_contract {
    delete the facility 
    @param group_id
    @author Tony Tseng <tony@arsdigita.com>
    @creation-date 10/26/00
    @cvs-id delete-2.tcl,v 1.1.2.1 2000/10/30 21:02:30 tony Exp
} {
    facility_id:naturalnum
}

#check if the user is an admin
set user_id [ad_verify_and_get_user_id]
if { ![im_is_user_site_wide_or_intranet_admin] } {
    ad_return_forbidden { Access denied } { You must be a site-wide or intranet administrator to delete a facility }
    return
}


db_transaction {
    db_dml delete_from_im_house_info {
	delete from im_house_info
	where facility_id=:facility_id
    }

    db_dml delete_form_im_facilities {
	delete from im_facilities
	where facility_id=:facility_id
    }

} on_error {
    ad_return_error "Oracle Error" "Oracle is complaining about this action:\n<pre>\n$errmsg\n</pre>\n"
    return
}


ad_returnredirect "index"

