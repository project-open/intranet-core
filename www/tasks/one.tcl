# /www/intranet/tasks/one.tcl
ad_page_contract {

  Displays the properties of one task.

  @param task_id Which task is being worked on
  @author jruiz@competitiveness.com 

} {

  task_id:naturalnum,notnull

}

db_1row task_properties "
select
  task,
  task_description,
  active,
  supervisor
from
  project_tasks
where
  task_id = :task_id"

set page_title $task

doc_return  200 text/html "[ad_admin_header $page_title]

<H2>$page_title</H2>

[ad_admin_context_bar [list "index" "Task"] "One task"]

<hr>

<form action=\"task-update\" method=post>
[export_form_vars task_id]
<table>
<tr>
<th align=right>Task name</th> 
<td><input size=40 name=task [export_form_value task]></td>
</tr>
<tr>
<th align=right>Supervisor</th> 
<td><input size=40 name=supervisor [export_form_value supervisor]></td>
</tr>
<tr>
<th align=right valign=top>Task description</th>
<td>
<textarea name=task_description rows=7 cols=70 wrap=soft>
[ns_quotehtml $task_description]
</textarea>
</td>
</tr>
<tr>
<th align=right>Actived</th><td>[bt_mergepiece  "<input type=radio name=active value=\"t\">Yes 
<input type=radio name=active value=\"f\">No" [ad_tcl_vars_to_ns_set active]]
</td>
</tr>
</table>
<center>
<input type=submit name=submit value=\"Update\">
</center>
</form>
<p>
<li><a href=\"task-nuke?[export_url_vars task_id]\">Nuke this task</a>

[ad_admin_footer]
"
