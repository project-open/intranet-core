# /www/intranet/reports/exception-missing-info-2.tcl

ad_page_contract {
    hurridly finishing the form submission for 
    expection-missing-info.tcl because half of it
    was checked out
 
    @param user Data keyed by user id
    @param other Optionally entered additional value for this
    user_id. Used only if user data is empty
    @param other_option used for type-checking user-entered values
    @param category_type Used if we're creating a new category for one of the values

    @author teadams@arsdigita.com 
    @creation-date  May 11, 2000

    @cvs-id exception-missing-info-2.tcl,v 1.1.2.6 2000/08/16 21:25:02 mbryzek Exp
} {
    user:array
    other:array
    exception_type:notnull
    { other_option "" }
    { category_type "" }
}

db_transaction {
    foreach user_id_for_update [array names user] {
	set varvalue [string trim $user($user_id_for_update)]
	if { [string equal $varvalue "no_update"] } {
	    set varvalue [string trim $other($user_id_for_update)]
	    if { [empty_string_p $varvalue] } {
		set varvalue no_update
	    } else {
		# Let's do some simply type checking here
		set valid_p 1
		switch $other_option {
		    "date" { set valid_p [philg_date_valid_p $varvalue] }
		}
		if { !$valid_p } {
		    ad_return_complaint 1 "<li>\"$varvalue\" is not in the proper format"
		    return
		}
		
		# Now let's see if we need to add a category
		if { ![empty_string_p $category_type] } {
		    # This means the other value is referring to a
		    # category. We have to add the category, grab the category_id, and do
		    # the appropriate update. Note that we don't care about the category
		    # error on insert - if there's an error, the category exists! 
		    set category $varvalue
		    # Some default value for the weight - we don't use this right now
		    set profiling_weight 10
		    set category_description [db_null]
		    set mailing_list_info [db_null]
		    # Don't enable the category - enabled categories are for users only
		    set enabled_p f
		    
		    # Note - because the categories table doesn't enforce a unique constraint 
		    # on category_type and category, we may have a concurrency issue here if 
		    # two threads run at the same time. There's not too much we can do short of 
		    # deleting multiple categories... We leave this for now
		    set category_sql {
			insert into categories
			(category_id, category, category_type, profiling_weight,
			category_description, mailing_list_info, enabled_p)
			select category_id_sequence.nextval, :category, :category_type, :profiling_weight,
			:category_description, :mailing_list_info, :enabled_p
			from dual
			where not exists (select 1 
			from categories c2
			where c2.category_type = :category_type
			and c2.category = :category)
		    }
		    
		    if { [catch { db_dml new_category_entry $category_sql } errmsg] } {
			ad_return_error "Database error" "We got the following error trying to create the category: <pre>$errmsg</pre>"
			return
		    }
		    
		    # Now let's pull out the category id
		    set category_id [db_string select_category_id {
			select c.category_id from categories c where category_type = :category_type and category=:category
		    }]
			
		    # Set varvalue to the category_id
		    set varvalue $category_id
		}
	    }
		
	}
	    
	# value is not no_update, then update the row
	if {![string match {no_update} [string trim $varvalue]] } {
	    # update the row
	    db_dml update_employee_info_statement \
		    "update im_employees
	                set $exception_type=:varvalue 
		      where user_id = :user_id_for_update" 
		
	}
    }
} on_error {
    ad_return_error "Database error" "We got the following error trying to process the previous form: <pre>$errmsg</pre>"
    return
    
}
	
db_release_unused_handles
ad_returnredirect "exception-missing-info?[export_url_vars exception_type]"

