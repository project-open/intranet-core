# /www/intranet/tasks/task-nuke-2.tcl
ad_page_contract {

  Actually nukes a task.

  @param task_id Task ID we're nuking

  @author jruiz@competitiveness.com

} {

  task_id:naturalnum,notnull

}


db_transaction {

    db_dml delete_task "delete from project_tasks where task_id = :task_id" 

} on_error {
    ad_return_error "Problem nuking task" "$errmsg"
    return
}

db_release_unused_handles

ad_returnredirect "index"

