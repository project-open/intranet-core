ad_page_contract {
    @cvs-id nuke-2.tcl,v 3.2.2.4.2.5 2000/09/22 01:36:18 kevin Exp
} {
    user_id:integer,notnull
}



# When there's a real orders table or system in place, 
# n_orders should be set to the result of a query that determines
# if the user has any orders
set n_orders 0

# Don't nuke anyone who pays us money ...
if { $n_orders > 0 } {
    ad_return_error "Can't Nuke a Paying Customer" "We can't nuke a paying customer because to do so would screw up accounting records."
    return
}

# have no mercy on the freeloaders

# if this fails, it will probably be because the installation has 
# added tables that reference the users table

with_transaction {
    # education module
    # TO DO: IF YOU UNCOMMENT THESE, MAKE USER_ID A BIND VARIABLE
    # This is assumes that all info added by a user is no longer wanted
    #db_dml unused "delete from edu_department_info where last_modifiying_user = :user_id"
    #db_dml unused "delete from edu_subjects where last_modifiying_user = :user_id"
    #db_dml unused "delete from edu_class_info where last_modifiying_user = :user_id"
    #db_dml unused "delete from edu_grades where last_modifiying_user = :user_id"
    #db_dml unused "delete from edu_student_tasks where assigned_by = $user_id"
    #db_dml unused "delete from edu_student_answers where student_id = $user_id"
    #db_dml unused "delete from edu_student_answers where student_id = $user_id"
    #db_dml unused "delete from edu_student_evaluations where student_id = $user_id"
    #db_dml unused "delete from edu_student_evaluations where grader_id = $user_id"
    #db_dml unused "delete from edu_student_evaluations where last_modifying_user = $user_id"
    #db_dml unused "delete from edu_task_instances where approving_user = $user_id"
    #db_dml unused "delete from edu_task_user_map where student_id = $user_id"
    #db_dml unused "delete from edu_appointments where user_id = $user_id"
    #db_dml unused "delete from edu_appointments_scheduled where user_id = $user_id"
    #db_dml unused "delete from portal_weather where user_id = $user_id"
    #db_dml unused "delete from portal_stocks where user_id = $user_id"
    #db_dml unused "delete from edu_calendar where owner = $user_id"
    #db_dml unused "delete from edu_calendar where creation_user = $user_id"
    

    # bboard system
    db_dml delete_user_bboard_email_alerts "delete from bboard_email_alerts where user_id = :user_id"
    db_dml delete_user_bboard_thread_email_alerts "delete from bboard_thread_email_alerts where user_id = :user_id"
    db_dml delete_user_bboard_unified "delete from bboard_unified where user_id = :user_id"
    
    # deleting from bboard is hard because we have to delete not only a user's
    # messages but also subtrees that refer to them
    bboard_delete_messages_and_subtrees_where  -bind [list user_id $user_id] "user_id = :user_id"
    
    # let's do the classifieds now
    db_dml delete_user_classified_auction_bids "delete from classified_auction_bids where user_id = :user_id"
    db_dml delete_user_classified_ads "delete from classified_ads where user_id = :user_id"
    db_dml delete_user_classified_email_alerts "delete from classified_email_alerts where user_id = :user_id"
    db_dml delete_user_neighbor_to_neighbor_comments "delete from general_comments 
 where on_which_table = 'neighbor_to_neighbor'
 and on_what_id in (select neighbor_to_neighbor_id 
                   from neighbor_to_neighbor 
                   where poster_user_id = :user_id)"
    db_dml delete_user_neighbor_to_neighbor "delete from neighbor_to_neighbor where poster_user_id = :user_id"
    # now the calendar
    db_dml delete_user_calendar "delete from calendar where creation_user = :user_id"
    # contest tables are going to be tough
    set all_contest_entrants_tables [db_list unused "select entrants_table_name from contest_domains"]
    foreach entrants_table $all_contest_entrants_tables {
	db_dml delete_user_contest_entries "delete from $entrants_table where user_id = :user_id"
    }

    # spam history
    db_dml delete_user_spam_history "delete from spam_history where creation_user = :user_id"
    db_dml delete_user_spam_history_sent "update spam_history set last_user_id_sent = NULL
                    where last_user_id_sent = :user_id"

    # calendar
    db_dml delete_user_calendar_categories "delete from calendar_categories where user_id = :user_id"

    # sessions
    db_dml delete_user_sec_sessions "delete from sec_sessions where user_id = :user_id"
    db_dml delete_user_sec_login_tokens "delete from sec_login_tokens where user_id = :user_id"
    
    # general stuff
    db_dml delete_user_general_comments "delete from general_comments where user_id = :user_id"
    db_dml delete_user_comments "delete from comments where user_id = :user_id"
    db_dml delete_user_links "delete from links where user_id = :user_id"
    db_dml delete_user_chat_msgs "delete from chat_msgs where creation_user = :user_id"
    db_dml delete_user_query_strings "delete from query_strings where user_id = :user_id"
    db_dml delete_user_user_curriculum_map "delete from user_curriculum_map where user_id = :user_id"
    db_dml delete_user_user_content_map "delete from user_content_map where user_id = :user_id"
    db_dml delete_user_user_group_map "delete from user_group_map where user_id = :user_id"

    # core tables
    db_dml delete_user_users_interests "delete from users_interests where user_id = :user_id"
    db_dml delete_user_users_charges "delete from users_charges where user_id = :user_id"
    db_dml set_referred_null_user_users_demographics "update users_demographics set referred_by = null where referred_by = :user_id"
    db_dml delete_user_users_demographics "delete from users_demographics where user_id = :user_id"
    db_dml delete_user_users_preferences "delete from users_preferences where user_id = :user_id"
    db_dml delete_user_users_contact "delete from users_contact where user_id = :user_id"
    db_dml delete_user "delete from users where user_id = :user_id"
} {
    
    set detailed_explanation ""

    if {[ regexp {integrity constraint \([^.]+\.([^)]+)\)} $errmsg match constraint_name]} {
	
	set sql "select table_name from user_constraints 
	where constraint_name=:constraint_name"

	db_foreach user_constraints_by_name $sql {
	    set detailed_explanation "<p>
	    It seems the table we missed is $table_name."
	}
    }

    ad_return_error "Failed to nuke" "The nuking of user $user_id failed.  Probably this is because your installation of the ArsDigita Community System has been customized and there are new tables that reference the users table.  Complain to your programmer!  

$detailed_explanation

<p>

For good measure, here's what the database had to say...

<blockquote>
<pre>
$errmsg
</pre>
</blockquote>"
    return
}

set page_content "[ad_admin_header "Done"]

<h2>Done</h2>

<hr>

We've nuked user $user_id.  You can <a href=\"/intranet/users/\">return
to user administration</a> now.

[ad_admin_footer]
"


doc_return  200 text/html $page_content
