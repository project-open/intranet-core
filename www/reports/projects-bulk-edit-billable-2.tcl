# /www/intranet/reports/projects-bulk-edit-billable-2.tcl

ad_page_contract {
    Bulk edits billable_p column for projects

    @param project Array keyed by project_id. Value is the selected option

    @author umathur@arsdigita.com
    @cvs-id projects-bulk-edit-billable-2.tcl,v 1.1.2.1 2000/08/16 21:28:41 mbryzek Exp

} {
    project:array,integer
    old_project:array,integer
}

# all of the updates effect the same table the exception_type is the name of the column

db_transaction {
    foreach group_id [array names project] {
	set billable_value $project($group_id)
	if { [info exists old_project($group_id)] && $old_project($group_id) == $billable_value} {
	    # Value was unchanged - skip it. This is important to not overload the db with dml 
	    continue
	}
	db_dml update_projects_billable \
		"update im_projects set billable_type_id=:billable_value where group_id = :group_id"
    }
}

db_release_unused_handles

ad_returnredirect index
