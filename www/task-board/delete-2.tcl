# /www/intranet/task-board/delete-2.tcl

ad_page_contract {

    Deletes a task from the database

    @param task_id Task we're deleting

    @author mbryzek@arsdigita.com
    @creation-date Wed Aug  9 22:35:26 2000
    @cvs-id delete-2.tcl,v 1.1.2.1 2000/08/16 21:28:44 mbryzek Exp

} {
    task_id:naturalnum,notnull
}

if { ![db_0or1row select_posting_id_for_task \
	"select tb.poster_id 
           from intranet_task_board tb
          where tb.task_id = :task_id"] } {
    # No such task exists - it's already deleted (or never existed). Just
    # redirect as this is not really an error.
    ad_returnredirect index
    return
}


# Already verified by filters
set user_id [ad_get_user_id]

# ONly the posting user or an admin can edit/delete a task
if { $poster_id != $user_id && ![im_is_user_site_wide_or_intranet_admin $user_id] } {
    ad_return_error "You can't delete this task" "You do not have permission to remove this task. Only the person who posted the task or an administrator can remove it."
    return
}

db_dml delete_task "delete from intranet_task_board where task_id=:task_id"

db_release_unused_handles

ad_returnredirect index