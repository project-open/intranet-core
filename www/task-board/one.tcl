# /www/intranet/task-board/one.tcl

ad_page_contract {
    
    lists one task

    @param task_id Task we're looking at

    @author Tracy Adams (teadams@arsdigita.com) 
    @creation-date July 17th, 2000
    @cvs-id one.tcl,v 1.2.2.2 2000/09/22 01:38:50 kevin Exp
    
} {
    task_id:integer,notnull
}


set user_id [ad_maybe_redirect_for_registration]

set sql "select tb.task_name, tb.body, tb.next_steps, tb.post_date,
                u.user_id as poster_id, u.first_names || ' ' || last_name as poster_name, 
                (select category from categories where category_id = time_id) as time, 
                tb.active_p, tb.expiration_date 
          from users u, intranet_task_board tb
         where u.user_id = tb.poster_id
           and tb.task_id = :task_id"

if { ![db_0or1row task_information $sql] } {
    ad_return_error "Task doesn't exist" "Task $task_id doesn't exist"]
    return
}

set context_bar [ad_context_bar  [list "index" "Task Board"] "One task"]

set page_content "
[im_header $task_name]
<table>
<tr><th align=right valign=top>Task</th><td>
$task_name (Posted by: <a href=/shared/community-member?user_id=$poster_id>$poster_name</a> on [util_AnsiDatetoPrettyDate $post_date])</td></tr>

<tr><th align=right valign=top>Expected time</th><td> $time</td></tr>
<tr><th align=right valign=top>Description</th><td>$body</td></tr>
<tr><th align=right valign=top>Next Step</th><td>$next_steps</td></tr>
</table>

<i>Expires [util_AnsiDatetoPrettyDate $expiration_date]</i>
"


# ONly the posting user or an admin can edit/delete a task
if { $poster_id == $user_id || [im_is_user_site_wide_or_intranet_admin $user_id] } {
    set return_url "one?[export_url_vars task_id]"
    # Note that we let people edit expired tasks so that they can 
    # re-enable them by adding a new expiration in the future
    append page_content "
<p><b>Administration</b>
<ul>
  <li> <a href=ae?[export_url_vars task_id return_url]>Edit this task</a>
  <li> <a href=delete?[export_url_vars task_id]>Delete this task</a>
</ul>
"
}


append page_content [im_footer]
 
doc_return  200 text/html $page_content
