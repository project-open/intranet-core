# /www/intranet/tasks/task-nuke.tcl
ad_page_contract {

  Confirmation page for nuking a task.

  @param task_id Task ID we're about to nuke

  @author jruiz@competitiveness.com

} {

  task_id:naturalnum,notnull

}


set task [db_string task_name "select task from project_tasks where task_id = :task_id" ]

doc_return  200 text/html "[ad_admin_header "Nuke task"]

<h2>Nuke task</h2>

[ad_admin_context_bar [list index "Tasks"] "Nuke task"]

<hr>

<form action=task-nuke-2 method=post>

[export_form_vars task_id]

<center>

Are you sure that you want to nuke the task \"$task\"? This action cannot be undone.

<p>

<input type=submit value=\"Yes, nuke this task now\">

</form>

[ad_admin_footer]
"
