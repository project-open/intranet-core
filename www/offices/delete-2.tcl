# /www/intranet/offices/delete-2.tcl

ad_page_contract {
    deletes the office and entries about the office from all the im tables.
    once that's done, redirect to the user group deletion page.
    @param group_id
    @author Tony Tseng <tony@arsdigita.com>
    @creation-date 10/26/00
    @cvs-id delete-2.tcl,v 1.1.2.1 2000/10/30 20:50:23 tony Exp
} {
    group_id:naturalnum
}

#check if the user is an admin
set user_id [ad_verify_and_get_user_id]
if { ![ad_permission_p site_wide "" "" $user_id] } {
    ad_return_forbidden { Access denied } { Since this action involves deleting a user group, you must be a site-wide administrator to perform it. }
}

db_transaction {
    #delete links
    db_dml delete_links {
	delete from im_office_links
	where group_id=:group_id
    }
    
    #delete office from im_offices
    db_dml delete_office {
	delete from im_offices
	where group_id=:group_id
    }
    
    #update im_employee_pipeline
    set null_val [db_null]
    db_dml update_pipeline {
	update im_employee_pipeline
	set office_id=:null_val
	where office_id=:group_id
    }
} on_error {
    ad_return_error "Oracle Error" "Oracle is complaining about this action:\n<pre>\n$errmsg\n</pre>\n"
    return
}

set return_url "/intranet/offices/"
ad_returnredirect "/admin/ug/group-delete-2?[export_url_vars group_id return_url]"

