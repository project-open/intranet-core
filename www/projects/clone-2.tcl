# /packages/intranet-core/projects/clone-2.tcl
#
# Copyright (C) 1998-2004 various parties
# The software is based on ArsDigita ACS 3.4
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_page_contract {
    Purpose: Create a copy of an existing project
    
    @param parent_id the parent project id
    @param return_url the url to return to

    @author avila@digiteix.com
    @author frank.bergmann@project-open.com
} {
    parent_project_id:integer
    project_nr
    project_name
    { clone_postfix "Clone" }
    { return_url "" }
}


# ---------------------------------------------------------------------
# Local procs
# ---------------------------------------------------------------------


ad_proc im_project_clone {parent_project_id project_name project_nr clone_postfix} {
    Clone project main routine
} {
    ns_log Notice "im_project_clone parent_project_id=$parent_project_id project_name=$project_name project_nr=$project_nr clone_postfix=$clone_postfix"

    set errors "<li>Starting to clone project \#$parent_project_id => $project_nr / $project_name"
#    set new_project_id [im_project_clone_base $parent_project_id $project_name $project_nr $clone_postfix]

    set parent_project_id 10745
    set new_project_id 13375

    # --------------------------------------------
    # Delete Costs
    ns_log Notice "im_project_clone: reset_invoice_items"
    db_dml reset_invoice_items "update im_invoice_items set project_id = null where project_id = :new_project_id"

    ns_log Notice "im_project_clone: cost_infos"
    set cost_infos [db_list_of_lists costs "select cost_id, object_type from im_costs, acs_objects where cost_id = object_id and project_id = :new_project_id"]
    foreach cost_info $cost_infos {
        set cost_id [lindex $cost_info 0]
        set object_type [lindex $cost_info 1]
        ns_log Notice "im_projects_clone: deleting cost: ${object_type}__delete($cost_id)"
        im_exec_dml del_cost "${object_type}__delete($cost_id)"
    }
    ns_log Notice "im_project_clone: finished deleting old costs"

    # --------------------------------------------
    # Delete Trans Tasks
    db_dml delete_trans_tasks "delete from im_trans_tasks where project_id = :new_project_id"


    append errors [im_project_clone_forum_topics $parent_project_id $new_project_id]
    
    append errors [im_project_clone_base2 $parent_project_id $new_project_id]
    append errors [im_project_clone_members $parent_project_id $new_project_id]
    append errors [im_project_clone_url_map $parent_project_id $new_project_id]
    append errors [im_project_clone_trans_tasks $parent_project_id $new_project_id]
    append errors [im_project_clone_target_languages $parent_project_id $new_project_id]



#    append errors [im_project_clone_subprojects $parent_project_id $new_project_id]

# Skipped meanwhile

#    append errors [im_project_clone_costs $parent_project_id $new_project_id]
#    append errors [im_project_clone_timesheet $parent_project_id $new_project_id]
#    append errors [im_project_clone_timesheet2_tasks $parent_project_id $new_project_id]


    append errors "<li>Finished to clone project \#$parent_project_id"

    return $errors
}




ad_proc im_project_clone_base {parent_project_id project_name project_nr clone_postfix} {
    Create the minimum information for a clone project
    with a new name and project_nr for unique constraint reasons.
} {
    ns_log Notice "im_project_clone_base parent_project_id=$parent_project_id project_name=$project_name project_nr=$project_nr clone_postfix=$clone_postfix"

    set org_project_name $project_name
    set org_project_nr $project_nr
    set current_user_id [ad_get_user_id]

    # --------------------------
    # Prepare Project SQL Query
    
    set query "
	select	p.*
	from	im_projects p
	where 	p.project_id = :parent_project_id
    "

    if { ![db_0or1row projects_info_query $query] } {
	set project_id $parent_project_id
	ad_return_complaint 1 "[_ intranet-core.lt_Cant_find_the_project]"
	return
    }
	
    # ------------------------------------------
    # Fix name and project_nr
    
    # Create a new project_nr if it wasn't specified
    if {"" == $org_project_nr} {
	set org_project_nr [im_next_project_nr]
    }

    # Use the parents project name if none was specified
    if {"" == $org_project_name} {
	set org_project_name $project_name
    }

    # Append "Postfix" to project name if it already exists:
    while {[db_string count "select count(*) from im_projects where project_name = :org_project_name"]} {
	set org_project_name "$org_project_name - $clone_postfix"
    }


    # -------------------------------
    # Create the new project
	
    set project_id [project::new \
		-project_name		$org_project_name \
		-project_nr		$org_project_nr \
		-project_path		$org_project_nr \
		-company_id		$company_id \
		-parent_id		$parent_id \
		-project_type_id	$project_type_id \
		-project_status_id	$project_status_id \
    ]
    if {0 == $project_id} {
	ad_return_complaint 1 "Error creating clone project with name '$org_project_name' and nr '$org_project_nr'"
	return 0
    }

    return $project_id
}




ad_proc im_project_clone_base2 {parent_project_id new_project_id} {
    copy project structure
} {
    ns_log Notice "im_project_clone_base2 parent_project_id=$parent_project_id new_project_id=$new_project_id"
    set errors "<li>Starting to clone base2 information: parent_project_id=$parent_project_id new_project_id=$new_project_id"

    set query "
	select	p.*
	from	im_projects p
	where 	p.project_id = :parent_project_id
    "

    if { ![db_0or1row projects_info_query $query] } {
	append errors "<li>[_ intranet-core.lt_Cant_find_the_project]"
	return $errors
    }


    # -----------------------------------------
    # Update project fields
    # Cover all fields that are not been used in project generation

    set project_update_sql "
	update im_projects set
		project_lead_id =	:project_lead_id,
		supervisor_id =		:supervisor_id,
		description =		:description,
		note =			:note,
		requires_report_p =	:requires_report_p,
		project_budget =	:project_budget,
		project_budget_currency=:project_budget_currency,
		project_budget_hours =	:project_budget_hours,
		percent_completed = 	:percent_completed,
		on_track_status_id =	:on_track_status_id,
		start_date =		:start_date,
		end_date =		:end_date
	where
		project_id = :new_project_id
    "
    db_dml project_update $project_update_sql


    # Translation Only
    if {[db_table_exists im_trans_tasks]} {
	set project_update_sql "
	update im_projects set
		company_project_nr =	:company_project_nr,
		company_contact_id =	:company_contact_id,
		source_language_id =	:source_language_id,
		subject_area_id =	:subject_area_id,
		expected_quality_id =	:expected_quality_id,
		final_company =		:final_company,
		trans_project_words =	:trans_project_words,
		trans_project_hours =	:trans_project_hours
	where
		project_id = :new_project_id
        "
	db_dml project_update $project_update_sql
    }

    # ToDo: Add stuff for consulting projects

    # Costs Stuff
    if {[db_table_exists im_costs]} {
	set project_update_sql "
	update im_projects set
		cost_quotes_cache =		:cost_quotes_cache,
		cost_invoices_cache =		:cost_invoices_cache,
		cost_timesheet_planned_cache =	:cost_timesheet_planned_cache,
		cost_purchase_orders_cache =	:cost_purchase_orders_cache,
		cost_bills_cache =		:cost_bills_cache,
		cost_timesheet_logged_cache =	:cost_timesheet_logged_cache
	where
		project_id = :new_project_id
        "
	db_dml project_update $project_update_sql
    }

    append errors "<li>Finished to clone base2 information"
    return $errors
}




ad_proc im_project_clone_members {parent_project_id new_project_id} {
    Copy projects members and administrators
} {
    ns_log Notice "im_project_clone_members parent_project_id=$parent_project_id new_project_id=$new_project_id"
    set errors "<li>Starting to clone member information"
    set current_user_id [ad_get_user_id]

    if {![db_0or1row project_info "
        select  p.*
        from    im_projects p
        where   p.project_id = :parent_project_id
    "]} {
        ad_return_complaint 1 "[_ intranet-core.lt_Cant_find_the_project]"
        return
    }

    # -----------------------------------------------
    # Add Project Manager roles
    # - current_user (creator/owner)
    # - project_leader
    # - supervisor
    set admin_role_id [im_biz_object_role_project_manager]
    im_biz_object_add_role $current_user_id $new_project_id $admin_role_id 
    if {"" != $supervisor_id} { im_biz_object_add_role $supervisor_id $new_project_id $admin_role_id }
    if {"" != $project_lead_id} { im_biz_object_add_role $project_lead_id $new_project_id $admin_role_id }

    # -----------------------------------------------
    # Add Project members in their roles
    # There are other elements with relationships (invoices, ...),
    # but these are added when the other types of objects are
    # added to the project.

    set rels_sql "
	select 
		r.*,
		m.object_role_id,
		o.object_type
	from 
		acs_rels r 
			left outer join im_biz_object_members m 
			on r.rel_id = m.rel_id,
		acs_objects o
	where 
		r.object_id_two = o.object_id
		and r.object_id_one=:parent_project_id
    "
    db_foreach get_rels $rels_sql {
	if {"" != $object_role_id && "user" == $object_type} {
	    im_biz_object_add_role $object_id_two $new_project_id $object_role_id
	}
    }
    append errors "<li>Finished to clone member information"
    return $errors
}

    
ad_proc im_project_clone_url_map {parent_project_id new_project_id} {
    Copy projects URL Map
} {
    ns_log Notice "im_project_clone_url_map parent_project_id=$parent_project_id new_project_id=$new_project_id"
    set errors "<li>Starting to clone url map information"

    set url_map_sql "
	select url_type_id, url
	from im_project_url_map
	where project_id = :parent_project_id
    "
    db_foreach url_map $url_map_sql {
	db_dml create_new_pum "
	    insert into im_project_url_map 
		(project_id, url_type_id, url)
	    values
		(:project_id,:url_type_id,:url)
	"
    }
    append errors "<li>Finished to clone url map information"
    return $errors
}


ad_proc im_project_clone_costs {parent_project_id new_project_id} {
    Copy cost items and invoices
} {
    ns_log Notice "im_project_clone_costs parent_project_id=$parent_project_id new_project_id=$new_project_id"
    set current_user_id [ad_get_user_id]

    # ToDo: There are costs _associated_ with a project, 
    # but without project_id! (?)
    #

    set costs_sql "
	select	c.*,
		i.*,
		o.object_type
	from
		acs_objects o,
		im_costs c
		left outer join
			im_invoices i on c.cost_id = i.invoice_id
	where
		c.cost_id = o.object_id
		and project_id = :parent_project_id
    "
    db_foreach add_costs $costs_sql {

	set old_cost_id $cost_id

	set cost_insert_query "select im_cost__new (
		null,			-- cost_id
		:object_type,		-- object_type
		now(),			-- creation_date
		:current_user_id,	-- creation_user
		'[ad_conn peeraddr]',	-- creation_ip
		null,			-- context_id
	
		:cost_name,		-- cost_name
		:parent_id,		-- parent_id
		:new_project_id,	-- project_id
		:customer_id,		-- customer_id
		:provider_id,		-- provider_id
		:investment_id,		-- investment_id
	
		:cost_status_id,	-- cost_status_id
		:cost_type_id,		-- cost_type_id
		:template_id,		-- template_id
	
		:effective_date,	-- effective_date
		:payment_days,  	-- payment_days
		:amount,		-- amount
		:currency,		-- currency
		:vat,			-- vat
		:tax,			-- tax
	
		:variable_cost_p,	-- variable_cost_p
		:needs_redistribution_p, -- needs_redistribution_p
		:redistributed_p,	-- redistributed_p
		:planning_p,		-- planning_p
		:planning_type_id,	-- planning_type_id
	
		:description,		-- description
		:note			-- note
	)"

	set cost_id [db_exec_plsql cost_insert "$cost_insert_query"]
	set new_cost_id $cost_id

	# ------------------------------------------------
	# create invoices
	# ------------------------------------------------

	if {"im_invoice" == $object_type} {

	    set invoice_nr [im_next_invoice_nr]

	    set invoice_sql "
	        insert into im_invoices (
	                invoice_id,
	                company_contact_id,
	                invoice_nr,
	                payment_method_id
	        ) values (
	                :new_cost_id,
	                :company_contact_id,
	                :invoice_nr,
	                :payment_method_id
	        )
	    "
	    db_dml invoice_insert $invoice_sql
	
	    # -------------------------------------
	    # creation invoice project relation
	    # -------------------------------------
	    
	    set relation_query "select acs_rel__new(
		 null,
		 'relationship',
		 :new_project_id,
		 :invoice_id,
		 null,
		 null,
		 null
	    )"
	    db_exec_plsql insert_acs_rels "$relation_query"

	    set new_invoice_id $invoice_id


	    # ------------------------------------------------
	    # create invoice items
	    # ------------------------------------------------
	    set invoice_sql "
		select * 
		from im_invoice_items 
		where invoice_id = :old_cost_id
	    "

	    db_foreach add_invoice_items $invoice_sql {
		set new_item_id [db_nextval "im_invoice_items_seq"]
		set insert_invoice_items_sql "
			INSERT INTO im_invoice_items (
				item_id, item_name, 
				project_id, invoice_id, 
				item_units, item_uom_id, 
				price_per_unit, currency, 
				sort_order, item_type_id, 
				item_status_id, description
			) VALUES (
				:item_id, :item_name, 
				:new_project_id, :new_invoice_id, 
				:item_units, :item_uom_id, 
				:price_per_unit, :currency, 
				:sort_order, :item_type_id, 
				:item_status_id, :description
			)"
				
		db_dml insert_invoice_items $insert_invoice_items_sql
		
	    }
	}			
	
    }
}

ad_proc im_project_clone_trans_tasks {parent_project_id new_project_id} {
    Copy translation tasks and assignments
} {
    ns_log Notice "im_project_clone_trans_tasks parent_project_id=$parent_project_id new_project_id=$new_project_id"
    set errors "<li>Starting to clone translation tasks"

    db_dml trans_tasks "insert into im_trans_tasks (
		task_id,
		project_id,
		target_language_id,
		task_name,
		task_filename,
		task_type_id,
		task_status_id,
		description,
		source_language_id,
		task_units,
		billable_units,
		task_uom_id,
		invoice_id,
		match_x,match_rep,match100,match95,match85,match75,match50,match0,
		trans_id,
		edit_id,
		proof_id,
		other_id
	    ) (
            select 
		nextval('im_trans_tasks_seq'),
		:new_project_id,
		target_language_id,
		task_name,
		task_filename,
		task_type_id,
		task_status_id,
		description,
		source_language_id,
		task_units,
		billable_units,
		task_uom_id,
		null as invoice_id,
		match_x,match_rep,match100,match95,match85,match75,match50,match0,
		trans_id,edit_id,proof_id,other_id 
	    from 
		im_trans_tasks 
	    where 
		project_id = :parent_project_id
	)
    "
    append errors "<li>Finished to clone translation tasks"
    return $errors
}

ad_proc im_project_clone_target_languages {parent_project_id new_project_id} {
    Copy target languages and assignments
} {
    ns_log Notice "im_project_clone_target_languages parent_project_id=$parent_project_id new_project_id=$new_project_id"
    set errors "<li>Starting to clone target languages"

    if {[catch { db_dml target_languages "insert into im_target_languages (
		project_id,
		language_id
	    ) (
            select 
		:new_project_id,
		language_id
	    from 
		im_target_languages 
	    where 
		project_id = :parent_project_id
	)
    "} errmsg ]} {
	append errors "<li><pre>$errmsg\n</pre>"
    }
    append errors "<li>Finished to clone target languages"
    return $errors
}

ad_proc im_project_clone_timesheet2_tasks {parent_project_id new_project_id} {
    Copy translation tasks and assignments
} {
    ns_log Notice "im_project_clone_timesheet2 parent_project_id=$parent_project_id new_project_id=$new_project_id"

    # ------------------------------------------------
    # create timesheet2 tasks
    # ------------------------------------------------
}


ad_proc im_project_clone_payments {parent_project_id new_project_id} {
    Copy payments
} {
    ns_log Notice "im_project_clone_payments parent_project_id=$parent_project_id new_project_id=$new_project_id"
    set errors "<li>Starting to clone payments"

    set payments_sql "select * from im_payments where cost_id = :old_cost_id"
    db_foreach add_payments $payments_sql {
	set old_payment_id $payment_id
	set payment_id [db_nextval "im_payments_id_seq"]
	db_dml new_payment_insert "
			insert into im_payments ( 
				payment_id, 
				cost_id,
				company_id,
				provider_id,
				amount, 
				currency,
				received_date,
				payment_type_id,
				note, 
				last_modified, 
				last_modifying_user, 
				modified_ip_address
			) values ( 
				:payment_id, 
				:new_cost_id,
				:company_id,
				:provider_id,
			:amount, 
				:currency,
				:received_date,
				:payment_type_id,
			:note, 
				(select sysdate from dual), 
				:user_id, 
				'[ns_conn peeraddr]' 
			)"
		
    }
    append errors "<li>Finished to clone payments \#$parent_project_id"
    return $errors
}


ad_proc im_project_clone_timesheet {parent_project_id new_project_id} {
    Copy timesheet information(?)
} {
    ns_log Notice "im_project_clone_timesheet parent_project_id=$parent_project_id new_project_id=$new_project_id"

    set timesheet_sql "
	select 
		user_id as usr,
		day,
	  	hours,
	  	billing_rate,
	  	billing_currency,
	  	note 
	from 
		im_hours
	where 
		project_id = :parent_project_id
    "
    db_foreach timesheet $timesheet_sql {
	db_dml add_timesheet "
		insert into im_hours 
		(user_id,project_id,day,hours,billing_rate, billing_currency, note)
		values
		(:usr,:new_project_id,:day,:hours,:billing_rate, :billing_currency, :note)
	    "
    }
}

	
ad_proc im_project_clone_forum_topics {parent_project_id new_project_id} {
    Copy forum topics
} {
    ns_log Notice "im_project_clone_forum_topics parent_project_id=$parent_project_id new_project_id=$new_project_id"
    set errors "<li>Starting to clone forum topics"

    db_dml topic_delete "delete from im_forum_topics where object_id=:new_project_id"

    set forum_sql "
	select
		* 
	from
		im_forum_topics 
	where 
		object_id = :parent_project_id
		and not exists (
			select topic_id
			from im_forum_topics
			where object_id = 1111
		)
    " 
    db_foreach forum_topics $forum_sql {
	set old_topic_id $topic_id
	set topic_id [db_nextval "im_forum_topics_seq"]

	append errors "<li>Cloning forum topic #$topic_id"

	db_dml topic_insert {
		insert into im_forum_topics (
			topic_id, object_id, topic_type_id, 
			topic_status_id, owner_id, subject
		) values (
			:topic_id, :new_project_id, :topic_type_id, 
			:topic_status_id, :owner_id, :subject
		)
	}
	# ------------------------------------------------
	# create forums files
	# ------------------------------------------------
	set new_topic_id $topic_id
	db_foreach "get forum files" "select * from im_forum_files where msg_id = :old_topic_id" {
	    db_dml "create forum file" "insert into im_forum_files (
		msg_id,n_bytes,
		client_filename, 
		filename_stub,
		caption,content
	    ) values (
		:new_topic_id,:n_bytes,
		:client_filename, 
		:filename_stub,
		:caption,
		:content
	    )"
		
	}
		
	# ------------------------------------------------
	# create forums folders
	# ------------------------------------------------
	
	# ------------------------------------------------
	# create forum topics user map
	# ------------------------------------------------
	
    }

    append errors "<li>Finished to clone forum topics \#$parent_project_id"
    return $errors
}


ad_proc im_project_clone_subprojects {parent_project_id new_project_id} {
    Copy subprojects
} {
    ns_log Notice "im_project_clone_subprojects parent_project_id=$parent_project_id new_project_id=$new_project_id"

    subprojects_sql "
	select
		project_id as next_project_id
	from 
		im_projects
	where 
		parent_id = :parent_project_id
    "
    db_foreach subprojects $subprojects_sql {
		# go for the next project
		im_project_clone $next_project_id
    }
}




# ---------------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set required_field "<font color=red size=+1><B>*</B></font>"
set project_nr_field_size [ad_parameter -package_id [im_package_core_id] ProjectNumberFieldSize "" 20]

if {"" == $return_url} { set return_url "/intranet/projects/view?project_id=parent_id" }
set current_url [ns_conn url]

if {![im_permission $current_user_id add_projects]} { 
    ad_return_complaint "Insufficient Privileges" "
	<li>You don't have sufficient privileges to see this page."
}

# Make sure the user can read the parent_project
im_project_permissions $current_user_id $parent_project_id parent_view parent_read parent_write parent_admin
if {!$parent_read} {
    ad_return_complaint "Insufficient Privileges" "
	<li>You don't have sufficient privileges to see this page."
}


set page_body [im_project_clone $parent_project_id $project_name $project_nr $clone_postfix]

doc_return 200 text/html [im_return_template]



