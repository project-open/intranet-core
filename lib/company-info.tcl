ad_page_contract {
    company-info.tcl

    @author iuri sampaio (iuri.sampaio@gmail.com)
    @date 2010-10-30
}



# -----------------------------------------------------------
# Defaults & Security
# -----------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_employee_p [im_user_is_employee_p $user_id]

set return_url [im_url_with_query]
set current_url [ns_conn url]
set context_bar [im_context_bar [list ./ "[_ intranet-core.Companies]"] "[_ intranet-core.One_company]"]

if {0 == $company_id} {set company_id $object_id}
if {0 == $company_id} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_specify_a_1]"
    return
}


# Check permissions. "See details" is an additional check for
# critical information
im_company_permissions $user_id $company_id view read write admin
set see_details $read
set see_sales_details $admin

if {!$read} {
    ad_return_complaint "[_ intranet-core.lt_Insufficient_Privileg]" "
    <li>[_ intranet-core.lt_You_dont_have_suffici_2]"
    return
}

# Should we bother about State and ZIP fields?
set some_american_readers_p [parameter::get_from_package_key -package_key acs-subsite -parameter SomeAmericanReadersP -default 0]


# Check if the invoices was changed outside of ]po[...
im_audit -object_id $company_id -action before_update




# -----------------------------------------------------------
# Get everything about the company
# -----------------------------------------------------------


set extra_selects [list "0 as zero"]

db_foreach column_list_sql {} {
    switch $table_name {
	"im_companies" { set attribute_table "c." }
	"im_offices" { set attribute_table "o." }
	default { set attribute_table "" }
    }
    lappend extra_selects "${deref_plpgsql_function}(${attribute_table}${attribute_name}) as ${attribute_name}_deref"
}
set extra_select [join $extra_selects ",\n\t"]


db_1row company_get_info {}

set country_name [db_string company_get_cc {} -default ""]

set page_title $company_name
set left_column ""


if {$see_details} {
    set im_url_stub [im_url_stub]


    if {![empty_string_p $site_concept]} {
	# Add a "http://" before the web site if it starts with "www."...
	if {[regexp {www\.} $site_concept]} { 
	    set site_concept "http://$site_concept" 
	}    
    }
    

# ------------------------------------------------------
# Primary Contact
# ------------------------------------------------------

    set primary_contact_text ""
    set limit_to_users_in_group_id [im_employee_group_id]
    set primary_contact_id_p 1
    if { [empty_string_p $primary_contact_id] } {
	set primary_contact_id_p 0
	
	if { $admin } {
	    set primary_contact_url [export_vars -base "primary-contact" {company_id limit_to_users_in_group_id}]
	    
	}
    } else {
	
	
	if { $admin } {
	    set primary_contact_url [export_vars -base "primary-contact" {company_id limit_to_users_in_group_id}]
	    set im_gif_turn [im_gif turn "Change the primary contact"]
	    
	    set primary_contact_delete_url [export_vars -base "primary-contact-delete" {company_id return_url}]
	    set im_gif_delete [im_gif delete "Delete the primary contact"]

	}
    }

    
    # ------------------------------------------------------
    # Accounting Contact
    # ------------------------------------------------------
    
    set accounting_contact_text ""
    set limit_to_users_in_group_id [im_employee_group_id]
    set accounting_contact_id_p 1
    if { [empty_string_p $accounting_contact_id] } {
	
	set accounting_contact_id_p 0
	if { $admin } {
	    set accounting_contact_url [export_vars -base "accounting-contact" {company_id limit_to_users_in_group_id}]
	}
	
    } else {
	
	if { $admin } {
	    set accounting_contact_url [export_vars -base accounting-contact {company_id limit_to_users_in_group_id}]
	    set accounting_delete_url [export_vars -base accounting-contact-delete {company_id return_url}]
	    
	    set im_gif_turn [im_gif turn "Change the accounting contact"]
	    set im_gif_delete [im_gif delete "Delete the accounting contact"]
	    
	}
	
    }
    set ctr 1
    
    # ------------------------------------------------------
    # Continuation ...
    # ------------------------------------------------------
    set note_p 0
    if { ![empty_string_p $note] } {
	set note_p 1
	if {[expr $ctr % 2]} {
	    set bgcolor " class=rowodd "
	} else {
	    set bgcolor " class=roweven "
	}
    }


    # ------------------------------------------------------
    # Add DynField Columns to the display
    # ------------------------------------------------------
   
    db_multirow -extend {attrib_name value value_p bgcolor} company_dynfield_attribs dynfield_select {} {
	set var ${attribute_name}_deref
	set value [expr $$var]
	
	set value_p 0
	
	if {"" != [string trim $value]} {
	    set value_p 1
	    if {[expr $ctr % 2]} {
		set bgcolor " class=rowodd "
	    } else {
		set bgcolor " class=roweven "
	    }
	    
	    set attrib_name [lang::message::lookup "" intranet-core.$attribute_name $pretty_name]
	    incr ctr
	}
    }
    
}


# ------------------------------------------------------
# 
# ------------------------------------------------------

