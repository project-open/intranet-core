# /www/intranet/tasks/task-add.tcl
ad_page_contract {

  Display forms for adding a new task.

  @author jruiz@competitiveness.com 

} {

}

set task_id [db_string next_task_id "select project_tasks_sequence.nextval from dual"]

doc_return  200 text/html "[ad_admin_header  "Add a task"]

<H2>Add a task</H2>

[ad_admin_context_bar [list "index" "Tasks"] "Add"]

<hr>

<form action=\"task-add-2\" method=post>
[export_form_vars task_id ]

<table>
<tr>
<th align=right>Task name</th> 
<td><input size=40 name=task></td>
</tr>
<tr>
<th align=right>Supervisor</th>
<td><input size=40 name=supervisor></td>
</tr>
<tr>
<th align=right valign=top>Task description</th>
<td><textarea name=task_description rows=5 cols=50 wrap=soft></textarea></td>
</tr>
<tr>
<th align=right>Actived</th><td>
<input type=radio name=active value=\"t\">Yes 
<input type=radio name=active value=\"f\" checked>No
</td>
</tr>
</table>
<center>
<input type=submit name=submit value=\"Add\">
</center>
</form>

[ad_admin_footer]
"

