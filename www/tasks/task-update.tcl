# /www/intranet/tasks/task-update.tcl
ad_page_contract {

  Updates the properties of an existing task.

  @param task_id           Id of task we're updating
  @param task              Task name
  @param task_description  Task description
  @param active             Enabled as User Interest task

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
    append exception_text "<li>Please enter task name"
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


db_dml update_task_properties "
UPDATE project_tasks
SET task = :task,
task_description = :task_description,
supervisor = :supervisor,
active = :active,
date_entered = sysdate
WHERE task_id = :task_id" 

db_release_unused_handles

ad_returnredirect "index"








