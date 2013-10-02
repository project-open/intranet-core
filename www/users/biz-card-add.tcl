
if {![info exists return_url]} {
    ad_page_contract {
	
	Selection page to enter a new contact base data.
	
	@author Frank Bergmann frank.bergmann@project-open.com
	@creation-date 2008-03-28
	@cvs-id $Id$
    } {
	{first_names "" }
	{last_name "" }
	{email "" }
	{company_name "" }
	{profile 0 }
	{form_mode "edit" }
	{return_url ""}
	{orderby "rank,desc" }
	{button_search "" }
	{button_new_user_company "" }
	{also_add_to_biz_object "" }
    }
    set template_p 1
} else {
    if {![info exists email]} { set email "" }
    if {![info exists first_names]} { set first_names "" }
    if {![info exists last_name]} { set last_name "" }
    if {![info exists company_name]} { set company_name "" }
    if {![info exists also_add_to_biz_object]} { set also_add_to_biz_object "" }

    set button_new_user_company ""
    set form_mode "edit"
    set button_search ""
    set template_p 0
}

# --------------------------------------------------
# One or more companies have been specified as a context
#
if {[info exists limit_to_company_id] && "" != $limit_to_company_id && "" == $company_name} {
    set company_name_list [db_list company_list "select company_name from im_companies where company_id in ([join $limit_to_company_id ","])"]
    set company_name [join $company_name_list " "]
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

set search_results_p 0


# ------------------------------------------------------------------
# Normalize input fields
# ------------------------------------------------------------------
    
set found_user_id [db_string found_uid "select party_id from parties where lower(email) = :email" -default ""]
if {"" == $found_user_id} {
    set found_user_ids [db_list found_uids "select person_id from persons where lower(first_names) = :first_names and lower(last_name) = :last_name"]
    set found_user_id [lindex $found_user_ids 0]
}

if {"" != $found_user_id} {
    db_1row found_user_info "
	select	im_name_from_user_id(u.user_id) as found_user_name,
		email as found_user_email
	from	cc_users u
	where	u.user_id = :found_user_id
    "
}

set found_company_id [db_string found_uid "select company_id from im_companies where lower(company_name) = :company_name" -default ""]
if {"" == $found_company_id} {
    set found_company_id [db_string found_uid "select company_id from im_companies where lower(company_path) = :company_name" -default ""]
}



# ------------------------------------------------------------------
# Action
# ------------------------------------------------------------------

# Add a new user action - 
# Redirect to user new page and set profile according to type of contact
if {"" != $button_new_user_company} {
    ad_returnredirect [export_vars -base "/intranet-contacts/biz-card-add-3.tcl" {first_names last_name email company_name profile}]
}

# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set contact_options [list \
	[list [lang::message::lookup "" intranet-core.Customer "Customer"] customer] \
	[list [lang::message::lookup "" intranet-core.Provider "Provider"] provider] \
	[list [lang::message::lookup "" intranet-core.Employee "Employee"] employee] \
	[list [lang::message::lookup "" intranet-core.Undefined "Undefined"] undefined] \
]

set contact_options_sql "
	select	g.*
	from	groups g,
		im_profiles p
	where	g.group_id = p.profile_id and
		lower(g.group_name) not in (
			'accounting',
			'bug-tracker',
			'helpdesk',
			'hr managers',
			'p/o admins',
			'project managers',
			'sales',
			'senior managers'
		)
	order by
		lower(g.group_name)
"
set contact_options [list]
db_foreach contact_options $contact_options_sql {
    regsub {[^0-9a-zA-Z_]} [string tolower $group_name] "" group_name_key
    set group_name_pretty [lang::message::lookup "" intranet-core.$group_name_key $group_name]
    lappend contact_options [list \
	$group_name_pretty \
	$group_id
    ]
}


set form_id "contact"

ad_form \
    -name $form_id \
    -cancel_url $return_url \
    -action "/intranet/users/biz-card-add" \
    -has_edit 1 \
    -method GET \
    -mode $form_mode \
    -export {return_url} \
    -form {
        {profile:text(select),optional {label "[lang::message::lookup {} intranet-core.Contact_Type {Contact Type}]"} {options $contact_options}}
	{first_names:text(text),optional {label "[_ intranet-core.First_names]"} {html {size 30}}}
	{last_name:text(text),optional {label "[_ intranet-core.Last_name]"} {html {size 30}}}
    	{email:text(text),optional {label "[_ intranet-core.Email]"} {html {size 30}} {help_text ""}}
	{company_name:text(text),optional {label "[lang::message::lookup {} intranet-core.Company_name {Company Name}]"} {html {size 30}}}
	{button_search:text(submit) {label "[lang::message::lookup {} intranet-core.Search {Search}]"}}
	{also_add_to_biz_object:text(hidden),optional}
    }


if {[info exists company_name] && "" != $company_name} { template::element::set_value $form_id company_name $company_name }
if {[info exists also_add_to_biz_object] && "" != $also_add_to_biz_object} { template::element::set_value $form_id also_add_to_biz_object $also_add_to_biz_object }


# Show action buttons only if we have searched before
if {"" != $button_search} {

    ad_form -extend -name $form_id -form {
	{button_new_user_company:text(submit) {label "[lang::message::lookup {} intranet-core.New_User_Company {New User + Company}]"}}
    }
}



ad_form -extend -name $form_id -new_request {

    # Nada. No actin necessary (so far?)

} -on_submit {


    # ------------------------------------------------------------------
    # Build conditional SQL
    # ------------------------------------------------------------------

    set org_first_names [string trim $first_names]
    set org_last_name [string trim $last_name]
    set org_email [string tolower [string trim $email]]
    set org_company_name [string trim $company_name]

    set first_names [string tolower [string trim $first_names]]
    set last_name [string tolower [string trim $last_name]]
    set email [string tolower [string trim $email]]
    set company_name [string tolower [string trim $company_name]]



    set q_list [list]
    set contact_or_query [list]
    set company_or_query [list]
    if {"" != $first_names} { 
	foreach t $first_names { lappend q_list $t }
	lappend contact_or_query "lower(u.first_names) like '%$first_names%'"
    }
    if {"" != $last_name} { 
	foreach t $last_name { lappend q_list $t }
	lappend contact_or_query "lower(u.last_name) like '%$last_name%'"
    }
    if {"" != $email} { 
	foreach t $email { lappend q_list $t }
	lappend contact_or_query "lower(u.email) like '%$email%'"
    }
    if {"" != $company_name} { 
	foreach t $company_name { lappend q_list $t }
	lappend company_or_query "lower(c.company_name) like '%$company_name%'"
    }
    
    set q [join $q_list " | "]

    set contact_or_clause [join $contact_or_query "\n\t\t\tOR " ]
    if {"" == $contact_or_clause} { set contact_or_clause "1=0" }

    set company_or_clause [join $company_or_query "\n\t\t\tOR " ]
    if {"" == $company_or_clause} { set company_or_clause "1=0" }



    # ------------------------------------------------------------------
    # Build the user list
    # ------------------------------------------------------------------
    
    list::create \
	-name contact_list \
	-multirow contact_multirow \
	-key user_id \
	-no_data "[lang::message::lookup {} intranet-core.No_contacts_found {No contacts found}]" \
	-elements {
	    rank { 
		label "[lang::message::lookup {} intranet-core.Rank {Rank}]" 
	    }
	    first_names { 
		label "[lang::message::lookup {} intranet-core.First_names {First Names}]" 
		link_url_col user_url
	    }
	    last_name { 
		label "[lang::message::lookup {} intranet-core.Last_name {Last Name}]" 
		link_url_col user_url
	    }
	    email { 
		label "[lang::message::lookup {} intranet-core.Email {Email}]" 
		link_url_col user_url
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
	    company_html { 
		label "[lang::message::lookup {} intranet-core.Companies {Companies}]" 
		display_template {
			@contact_multirow.company_html;noquote@
		}
	    }
	    action {
		label ""
		display_template {
		    @contact_multirow.action_html;noquote@
		}
	    }
	} \
	-orderby {
	    rank {orderby rank}
	    first_names {orderby first_names}
	    contact_type {orderby contact_type}
	}

    
    set inner_sql "
			select	u.user_id,
				1 as rank
			from	cc_users u
			where	$contact_or_clause
		    UNION
			select	so.object_id as user_id,
		                (rank(so.fti, :q::tsquery) * sot.rel_weight)::numeric(12,2) as rank
			from	im_search_objects so,
				im_search_object_types sot
			where	so.object_type_id = sot.object_type_id and
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
		u.*, p.*, pa.*,
		cust.group_id as cust_group_id,
		prov.group_id as prov_group_id,
		empl.group_id as empl_group_id,
		im_company_list_for_user_html(u.user_id) as company_ids
	from
		($middle_sql) uu,
		persons p,
		parties pa,
		users u
		LEFT OUTER JOIN (
				select * from group_distinct_member_map 
				where group_id = [im_customer_group_id]
		) cust ON cust.member_id = u.user_id
		LEFT OUTER JOIN (
		     		select * from group_distinct_member_map 
				where group_id = [im_freelance_group_id]
		) prov ON prov.member_id = u.user_id
		LEFT OUTER JOIN (
		     	   	select * from group_distinct_member_map 
				where group_id = [im_employee_group_id]
		) empl ON empl.member_id = u.user_id
	where
		u.user_id = uu.user_id and
		u.user_id = p.person_id and
		u.user_id = pa.party_id and
		uu.rank > 0.08
	[template::list::orderby_clause -name contact_list -orderby]
    "
    
    set company_hash_sql "
	select	company_id,
		company_name
	from	im_companies	 		 
    "
    db_foreach company_hash $company_hash_sql {
    	set company_name_hash($company_id) $company_name
    }

    db_multirow -extend {company_html user_url delete_url contact_type action_html} contact_multirow get_similar_contacts $contact_sql {

	set user_url [export_vars -base "/intranet/users/view" { user_id return_url }]
	set delete_url [export_vars -base "contact-del" { object_type page_url }]
	set contact_type ""
	if {"" != $empl_group_id} { append contact_type [lang::message::lookup "" intranet-core.Employee "Employee"] }
	if {"" != $cust_group_id} { append contact_type [lang::message::lookup "" intranet-core.Customer "Customer"] }
	if {"" != $prov_group_id} { append contact_type [lang::message::lookup "" intranet-core.Provider "Provider"] }
	
	set also_add_users [list $user_id [im_biz_object_role_full_member]]
	set action_text [lang::message::lookup "" intranet-core.Create_new_company_for_this_user "New company for user"]
	set action_url [export_vars -base "/intranet/companies/new" {{company_name $org_company_name} return_url also_add_users}]
	set action_html "<a href='$action_url' class=button>$action_text</a>"

	set company_html ""
	foreach company_id $company_ids {
	    set company_name "<nobr>$company_name_hash($company_id)</nobr>"
	    append company_html "<a href='[export_vars -base "/intranet/companies/view" {company_id}]'>$company_name</a><br>\n"
	}
#	append company_html "&nbsp;<br>"
    }


    # ------------------------------------------------------------------
    # Build the company list
    # ------------------------------------------------------------------
    
    list::create \
	-name company_list \
	-multirow company_multirow \
	-key user_id \
	-no_data "[lang::message::lookup {} intranet-core.No_contacts_found {No companies found}]" \
	-elements {
	    rank { 
		label "[lang::message::lookup {} intranet-core.Rank {Rank}]" 
	    }
	    company_name { 
		label "[lang::message::lookup {} intranet-core.Company_name {Company Name}]" 
		link_url_col company_url
	    }
	    company_type { 
		label "Type" 
	    }
	    action {
		label ""
		display_template {
		    @company_multirow.action_html;noquote@
		}
	    }
	} \
	-orderby {
	    rank {orderby rank}
	    company_name {orderby company_name}
	    company_type {orderby company_type}
	}

    
    set inner_sql "
			select
				c.company_id,
				1 as rank
			from
				im_companies c
			where
				$company_or_clause
		    UNION
			select
				so.object_id as company_id,
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
	select	sum(c.rank) as rank,
		c.company_id
	from
		($inner_sql) c
	group by
	      c.company_id
    "

    set company_sql "
	select
		cc.rank,
		c.*,
		im_category_from_id(c.company_type_id) as company_type
	from
		($middle_sql) cc,
		im_companies c
	where
		c.company_id = cc.company_id and
		cc.rank > 0.13
	[template::list::orderby_clause -name company_list -orderby]
    "

    ns_log Notice "biz-card-add.tcl: Before executing db_multirow"

    db_multirow -extend {company_url action_html} company_multirow get_similar_companies $company_sql {

	set company_url [export_vars -base "/intranet/companies/new" { company_id return_url }]
	
	lappend also_add_to_biz_object [list $company_id [im_biz_object_role_full_member]]
	set action_text [lang::message::lookup "" intranet-core.Create_new_user_for_this_company "New user for company"]
	set action_url [export_vars -base "/intranet/users/new" {{first_names $org_first_names} {last_name $org_last_name} {email $org_email} profile return_url also_add_to_biz_object}]
	set action_html "<a href='$action_url' class=button>$action_text</a>"
    }

    ns_log Notice "biz-card-add.tcl: After executing db_multirow"

    set search_results_p 1

}
