# /www/intranet/task-board-new-2.tcl

ad_page_contract {
    
    posts a new tasks on the task board

    @param task_id Task we're either adding or deleting

    @author Tracy Adams (teadams@arsdigita.com) 
    @creation-date July 17th, 2000
    @cvs-id ae-2.tcl,v 1.3.2.1 2000/08/16 21:28:44 mbryzek Exp

} {
    task_id:integer,notnull
    category_id:integer,notnull
    { task_name "" }
    { body:html "" }
    { next_steps:html "" }
    expiration:array,date
    { return_url {[im_url_stub]} }
}

set user_id [ad_maybe_redirect_for_registration]

set exception_count 0
set exception_text ""

# check for not null start date
if { [info exists expiration(date) ] } {
    set expiration_date $expiration(date)
    # Make sure expiration is after today
    set expire_laterthan_future_p [db_string expiration_after_sysdate \
	    "select to_date('$expiration_date', 'yyyy-mm-dd')  - sysdate  from dual"]
    if {$expire_laterthan_future_p <= 0} {
	incr exception_count
	append exception_text "<li>Please make sure the expiration date is later than today."
    }

} else {
   incr exception_count
   append exception_text "<li> Please enter an expiration date"
}

# now expiration_date is set

if { [empty_string_p $task_name] } {
    incr exception_count
    append exception_text "<li>Please enter a task name."
}
if { [empty_string_p $body] } {
    incr exception_count
    append exception_text "<li>Please enter the task."
}

if { $exception_count > 0 } { 
    ad_return_complaint $exception_count $exception_text
    return
}



# First update, then insert

db_dml task_board_update "
update intranet_task_board 
   set task_name = :task_name,
       body = empty_clob(),
       next_steps = :next_steps,
       time_id = :category_id,
       expiration_date = :expiration_date
 where task_id = :task_id
returning body into :1" -clobs [list $body]

if { [db_resultrows] == 0 } {
    if { [catch {db_dml task_board_insert "
insert into intranet_task_board 
(task_id, task_name, body, next_steps, post_date, poster_id, time_id, active_p, expiration_date) 
values 
(:task_id, :task_name, empty_clob(), :next_steps, sysdate, :user_id, :category_id,  't', :expiration_date) returning body into :1" -clobs [list $body]  } errmsg] } {

    if { [db_string task_exists_p "select count(*) from intranet_task_board where task_id = :task_id"] == 0 } {
	ns_log Error "/news/post-new-3.tcl choked:  $errmsg"
 	ad_return_error "Insert Failed" "The Database did not like what you typed.  This is probably a bug in our code.  Here's what the database said:
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>
"
        return
    }
  }
}

ns_returnredirect $return_url


