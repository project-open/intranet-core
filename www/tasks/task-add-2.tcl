# /www/intranet/tasks/task-add-2.tcl
ad_page_contract {

  Inserts a new task.

  @param task_id          ID of newly created task
  @param task             Task name
  @param task_description Task description
  @param active            Enabled as User Interest task

  @author jruiz@competitiveness.com

} {

  task_id:naturalnum,notnull
  task:notnull
  task_description
  supervisor
  active:notnull

}

set exception_count 0
set exception_text ""

if {![info exists task_id] || [empty_string_p $task_id]} {
    incr exception_count
    append exception_text "<li>Task ID is somehow missing.  This is probably a bug in our software."
}

if {![info exists task] || [empty_string_p $task]} {
    incr exception_count
    append exception_text "<li>Please enter a task"
}

if {[info exists task_description] && [string length $task_description] > 4000} {
    incr exception_count
    append exception_text "<li>Please limit your task description to 4000 characters"
}

set naughty_html_text [ad_check_for_naughty_html "$task $task_description"]

if { ![empty_string_p $naughty_html_text] } {
    append exception_text "<li>$naughty_html_text"
    incr exception_count
}


if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text 
    return
}

db_transaction {
    db_dml new_task_entry {
	insert into project_tasks
	(task_id, task, task_description, supervisor, active, date_entered)
	values
	(:task_id, :task, :task_description, :supervisor, :active, sysdate)
    }

} on_error {
    ad_return_complaint "Database Error" "<!--$task_id, $task, $task_description, $supervisor, $active -->was:
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>

    "
}

db_release_unused_handles

ad_returnredirect "index"
