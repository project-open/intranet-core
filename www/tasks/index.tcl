# /www/intranet/tasks/index.tcl
ad_page_contract {

  Home page for task administration.

  @author jruiz@competitiveness.com
} {

}

set return_html "

[ad_admin_header "Content Tasks"]

<h2>Content Tasks</h2>

[ad_admin_context_bar "Tasks"]

<hr>
<br>
<ul>
"

set n_task [db_string n_task "select count(*)
from project_tasks
where task_id is not null"]

if { $n_task > 0 } {

    db_foreach existing_tasks "
    select task_id, task from project_tasks order by task" {
    append return_html "<li><a href=\"one?[export_url_vars task_id]\">$task</a>\n"
    }
}

    append return_html "
</ul>
<p>
<li><a href=\"task-add\">Add a task</a>
</ul>

"

append return_html "[ad_admin_footer]\n"

doc_return  200 text/html $return_html
