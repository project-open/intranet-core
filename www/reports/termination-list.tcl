# /www/intranet/reports/termination-list.tcl

ad_page_contract {
    This page will list recently terminated employees.
It will have a pulldown menu at the top to select start
and end blocks
ad_maybe_redirect_for_registration
    
    @param user_id_from_search
    @param start_block
    @param end_block

    @author Uday Mathur  umathur@arsdigita.com
    @creation-date 


    @cvs-id termination-list.tcl,v 1.6.2.8 2000/09/22 01:38:47 kevin Exp
} {
    { user_id_from_search:integer "" }
    { start_block: "" }
    { end_block: "" }
}

ad_maybe_redirect_for_registration

set user_id $user_id_from_search

if { ![info exists end_block] } {
    set end_block [db_string max_end_block "select max(start_block)
                                      from   im_start_blocks 
                                      where  start_block < sysdate"]
}

if { ![info exists start_block] } {
    set start_block  [db_string max_start_block "select max(start_block)
                                        from   im_start_blocks 
                                        where  start_block < to_date(:end_block,'yyyy-mm-dd') 
                                           and to_char(start_block,'W') = 1" ]
}

# note, we don't want to select those that have been fully hired
# and put in the employees table

set sql_query "select u.first_names||' '||u.last_name as name, info.termination_date, 
                      nvl(info.termination_reason,'<em>not specified</em>') as termination_reason,
                      info.voluntary_termination_p 
               from im_employees info, users u
               where info.user_id = u.user_id
               and info.termination_date is not null
               and termination_date >= to_date (:start_block, 'YYYY-MM-DD')
               and termination_date <= to_date (:end_block, 'YYYY-MM-DD')
               order by termination_date desc"

set termination_string ""
db_foreach get_employee $sql_query {
    append termination_string "<li>$name: terminated on [util_AnsiDatetoPrettyDate $termination_date], Reason: $termination_reason, Voluntary: [util_PrettyBoolean $voluntary_termination_p]\n"
} if_no_rows {
    append termination_string " <li> No terminated Employees"
}

set context_bar [ad_context_bar [list "[im_url_stub]/reports/" "Reports"] "Termination Report"]

set return_html "
[im_header "Termination Report"]
<form action=termination-list method=post>
From:
<select name=start_block>
[im_allocation_date_optionlist $start_block "t"]
</select>
To
<select name=end_block>
[im_allocation_date_optionlist $end_block "t"]
</select>
<input type=submit name=submit value=Go>
</form>"

append return_html "<ul>$termination_string</ul>
[im_footer]"
doc_return  200 text/html $return_html

