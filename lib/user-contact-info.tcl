ad_page_contract {
    user-contact-info.tcl

    @author unknown@arsdigita.com
    @author Guillermo Belcic (guillermo.belcic@project-open.com)
    @author frank.bergmann@project-open.com

    @author iuri sampaio(iuri.sampaio@gmail.com)
    @date 1020-10-29
}  


if {$user_id} {set user_id_from_search $user_id}
if {0 == $user_id} {
    # The "Unregistered Vistior" user
    # Just continue and show his data...
}

if {![info exists contact_view_name]} {
    set contact_view_name "user_contact"
}

set current_user_id [ad_maybe_redirect_for_registration]

# Check the permissions 
im_user_permissions $current_user_id $user_id_from_search view read write admin

# ToDo: Cleanup component to use $write instead of $edit_user
set edit_user $write

if {!$read} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient]"
    return
}

# ---------------------------------------------------------------
# Contact Information
# ---------------------------------------------------------------

set ha_country_code ""
set wa_country_code ""

set result [db_0or1row users_info_query {}]

# Get CCs outside of main select to avoid outer joins...
# iuri 2010-11-05 ha_country_code and wa_country_code are empty in this page!!!

set ha_country_name [util_memoize [list db_string ha_country_name "select country_name from country_codes where iso = '$wa_country_code'" -default ""]]

set wa_country_name [util_memoize [list db_string wa_country_name "select country_name from country_codes where iso = '$ha_country_code'" -default ""]]


if {$result == 1} {

    # Define the column headers and column contents that 
    # we want to show:
    #
    set view_id [db_string select_view_id "select view_id from im_views where view_name = '$contact_view_name'" ]


    set user_id $user_id_from_search

    set ctr 1

    db_multirow -extend {visible_p td_class column_render} user_columns column_list_sql {} {
        if {"" == $visible_for || [eval $visible_for]} {
	    set visible_p 1
	    
	    # Render the column_render
	    set cmd "set column_render $column_render_tcl"
	    eval $cmd

	    # L10n
	    regsub -all " " $column_name "_" column_name_subs
	    set column_name [lang::message::lookup "" intranet-core.$column_name_subs $column_name]

	    # Make sure to have the correct classes
	    if {[expr $ctr % 2]} {
		set td_class "class=rowodd"
	    } else { 
		set td_class "class=roweven"
	    }
	    incr ctr
	} else {
	    # It should not be visible
	    set visible_p 0
	}
    }
} else {
    # There is no contact information specified
    # => allow the user to set stuff up. "

    set user_id $user_id_from_search
}
