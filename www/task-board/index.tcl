# /www/intranet/task-board/index.tcl

ad_page_contract {
    
    lists all the active tasks

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date August 9th, 2000
    @cvs-id index.tcl,v 1.2.2.2 2000/09/22 01:38:50 kevin Exp
    
} {
}

set user_id [ad_maybe_redirect_for_registration]

set sql "select tb.task_name, tb.task_id, tb.expiration_date,
                tb.expiration_date - sysdate as expired_difference
          from intranet_task_board tb
         order by expiration_date desc"

set page_title "Task Board"
set context_bar [ad_context_bar  "Task board"]

set page_content "
[im_header]
<ul>
"

db_foreach list_all_tasks $sql {
    if { $expired_difference < 0 } {
	set expired_phrase "expired"
    } else {
	set expired_phrase "expires"
    }
    append page_content "  <li> <a href=one?[export_url_vars task_id]>$task_name</a> ($expired_phrase on [util_AnsiDatetoPrettyDate $expiration_date])\n"
} if_no_rows {
    append page_content "  <li> There are currently no tasks.\n"
}

append page_content "

<p><li><a href=ae>Post a new task</a>
</ul>
[im_footer]
"
 
doc_return  200 text/html $page_content
