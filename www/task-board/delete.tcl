# /www/intranet/task-board/delete.tcl

ad_page_contract {

    Confirms delete of one task

    @param task_id Task we're deleting

    @author mbryzek@arsdigita.com
    @creation-date Wed Aug  9 22:35:26 2000
    @cvs-id delete.tcl,v 1.1.2.2 2000/09/22 01:38:50 kevin Exp

} {
    task_id:naturalnum,notnull
}

if { ![db_0or1row basic_task_info \
	"select tb.task_name, tb.poster_id
           from intranet_task_board tb
          where tb.task_id = :task_id"] } {
   # Task already doesn't exist - just redirect to the index page
   ad_returnredirect index
   return
}

# Already verified by filters
set user_id [ad_maybe_redirect_for_registration]

# ONly the posting user or an admin can edit/delete a task
if { $poster_id != $user_id && ![im_is_user_site_wide_or_intranet_admin $user_id] } {
    ad_return_error "You can't delete this task" "You do not have permission to remove this task. Only the person who posted the task or an administrator can remove it."
    return
}


set page_title "Confirm task deletion"
set context_bar [ad_context_bar  [list "index" "Task Board"] [list one?[export_url_vars task_id] "One Task"] "Delete Task"]

set page_content "
[im_header]
Are you sure you want to delete the task named \"$task_name\"? 
<b>Note that there is no way to recover a deleted task.</b>

[im_yes_no_table delete-2 one [list task_id]]
[im_footer]
"

doc_return  200 text/html $page_content
