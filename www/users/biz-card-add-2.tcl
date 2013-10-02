ad_page_contract {

    Search page for existing contacts.
    Based on first_names, last_name, email and company_name
    shows existing contacts that might be duplicates.

    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2008-03-28
    @cvs-id $Id$

	@param object_type
		Defines the object to be created/saved

	@param group_ids 
		List of groups for the person to be added to.
		Groups are linked via categories (of the same name) to
		the DynField attributes to be shown.

	@param list_ids 
		List of object-subtypes for the im_company or im_office to 
		be created.
	
	@param object_types
		List of objects to create using this page. We will also
		create a link between these object types.
		Example: im_company + person => + company-person-membership
} {
    { first_names "" }
    { last_name "" }
    { email "" }
    { company_name "" }
    {form_mode "edit" }
    {return_url ""}
    {orderby "rank,desc" }
}

# --------------------------------------------------
# Append the option to create a user who get's a welcome message send
# Furthermore set the title.

set title "[_ intranet-contacts.Add_a_Biz_Card]"
set context [list $title]
set current_user_id [ad_maybe_redirect_for_registration]


# --------------------------------------------------
# Environment information for the rest of the page

set package_id [ad_conn package_id]
set package_url [ad_conn package_url]
set user_id [ad_conn user_id]
set peeraddr [ad_conn peeraddr]
set required_field "<font color=red size=+1><B>*</B></font>"


# ------------------------------------------------------------------
# Build the list
# ------------------------------------------------------------------

lappend action_list "Add page" "[export_vars -base "layout-page" { object_type }]" "Add item to this order"

list::create \
    -name contact_list \
    -multirow contact_multirow \
    -key user_id \
    -actions $action_list \
    -no_data "[lang::message::lookup {} intranet-core.No_contacts_found {No contacts found}]" \
    -elements {
	rank { 
	    label "[lang::message::lookup {} intranet-core.Rank {Rank}]" 
	}
	first_names { 
	    label "[lang::message::lookup {} intranet-core.First_names {First Names}]" 
	    link_url_col details_url
	}
	last_name { 
	    label "[lang::message::lookup {} intranet-core.Last_name {Last Name}]" 
	    link_url_col details_url
	}
	email { 
	    label "[lang::message::lookup {} intranet-core.Email {Email}]" 
	    link_url_col details_url
	}
	contact_type { 
	    label "Type" 
	    display_template {
		<if @contact_multirow.contact_type@ eq "relative">
		<a href="@contact_multirow.edit_url@" class="button">@contact_multirow.contact_type@</a>
		</if>
		<else>
		@contact_multirow.contact_type@
		</else>
	    }
	}
	action {
	    label ""
	    display_template {
		<a href="@contact_multirow.delete_url@" class="button">#acs-kernel.common_Delete#</a>
	    }
	}
    } \
    -orderby {
	rank {orderby rank}
	first_names {orderby first_names}
	contact_type {orderby contact_type}
    }

set first_names [string tolower [string trim $first_names]]
set last_name [string tolower [string trim $last_name]]
set email [string tolower [string trim $email]]
set company_name [string tolower [string trim $company_name]]

set q_list [list]
set or_query [list]
if {"" != $first_names} { 
   lappend q_list $first_names 
   lappend or_query "lower(u.first_names) like '%$first_names%'"
}
if {"" != $last_name} { 
   lappend q_list $last_name 
   lappend or_query "lower(u.last_name) like '%$last_name%'"
}
if {"" != $email} { 
   lappend q_list $email 
   lappend or_query "lower(u.email) like '%$email%'"
}
if {"" != $company_name} { 
   lappend q_list $company_name 
}

set q [join $q_list " | "]
set or_clause [join $or_query "\n\t\t\tOR " ]
if {"" == $or_clause} { set or_clause "1=0" }


set inner_sql "
			select
				u.user_id,
				1 as rank
			from
				cc_users u
			where
				$or_clause
		    UNION
			select
				so.object_id as user_id,
		                (rank(so.fti, :q::tsquery) * sot.rel_weight)::numeric(12,2) as rank
			from
				im_search_objects so,
				im_search_object_types sot
			where
				so.object_type_id = sot.object_type_id and
				so.fti @@ to_tsquery('default',:q)
"

# Sum up the ranks of the two searches
set middle_sql "
	select	sum(u.rank) as rank,
		u.user_id
	from
		($inner_sql) u
	group by
	      u.user_id
"

set contact_sql "
	select
		uu.rank,
		u.*,
		cust.group_id as cust_group_id,
		prov.group_id as prov_group_id,
		empl.group_id as empl_group_id
	from
		($middle_sql) uu,
		cc_users u
		LEFT OUTER JOIN (select * from group_distinct_member_map where group_id = [im_customer_group_id]) cust ON cust.member_id = u.user_id
		LEFT OUTER JOIN (select * from group_distinct_member_map where group_id = [im_freelance_group_id]) prov ON prov.member_id = u.user_id
		LEFT OUTER JOIN (select * from group_distinct_member_map where group_id = [im_employee_group_id]) empl ON empl.member_id = u.user_id
	where
		u.user_id = uu.user_id
	[template::list::orderby_clause -name contact_list -orderby]
"

db_multirow -extend {delete_url contact_type} contact_multirow get_similar_contacts $contact_sql {

    set delete_url [export_vars -base "contact-del" { object_type page_url }]
    set contact_type ""
    if {"" != $empl_group_id} { append contact_type [lang::message::lookup "" intranet-core.Employee "Employee"] }
    if {"" != $cust_group_id} { append contact_type [lang::message::lookup "" intranet-core.Customer "Customer"] }
    if {"" != $prov_group_id} { append contact_type [lang::message::lookup "" intranet-core.Provider "Provider"] }

}
