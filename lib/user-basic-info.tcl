ad_page_contract {
    user-basic-info.tcl


    @author unknown@arsdigita.com
    @author Guillermo Belcic (guillermo.belcic@project-open.com)
    @author frank.bergmann@project-open.com

    @author iuri sampaio(iuri.sampaio@gmail.com)
    @date 1020-10-28
} {
    { object_id:integer 0}
    { user_id_from_search 0}
    { view_name "user_view" }
    { contact_view_name "user_contact" }
    { freelance_view_name "user_view_freelance" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set return_url [im_url_with_query]
set current_url $return_url

set date_format "YYYY-MM-DD"

# user_id is a bad variable for the object,
# because it is overwritten by SQL queries.
# So first find out which user we are talking
# about...

if {"" == $user_id} { set user_id 0 }
set vars_set [expr ($user_id > 0) + ($object_id > 0) + ($user_id_from_search > 0)]
if {$vars_set > 1} {
    ad_return_complaint 1 "<li>You have set the user_id in more then one of the following parameters: <br>user_id=$user_id, <br>object_id=$object_id and <br>user_id_from_search=$user_id_from_search."
    return
}
if {$object_id} {set user_id_from_search $object_id}
if {$user_id} {set user_id_from_search $user_id}
if {0 == $user_id} {
    # The "Unregistered Vistior" user
    # Just continue and show his data...
}

set current_user_id [ad_maybe_redirect_for_registration]
set subsite_id [ad_conn subsite_id]

# Check the permissions 
im_user_permissions $current_user_id $user_id_from_search view read write admin

# ToDo: Cleanup component to use $write instead of $edit_user
set edit_user $write

if {!$read} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient]"
    return
}


# ---------------------------------------------------------------
# Get everything about the user
# ---------------------------------------------------------------

set result [db_0or1row users_info_query {}]

if { $result > 1 } {
    ad_return_complaint "[_ intranet-core.Bad_User]" "
    <li>There is more then one user with the ID $user_id_from_search"
    return
}

if { $result == 0 } {

    set party_id [db_string select_party_id {} -default 0]
    set person_id [db_string select_person_id {} -default 0]
    set user_id [db_string select_user_id {} -default 0]
    set object_type [db_string select_object_type {} -default "unknown"]

    ad_return_complaint "[_ intranet-core.Bad_User]" "
    <li>[_ intranet-core.lt_We_couldnt_find_user_]
    <li>You can 
	<a href='/intranet/users/new?user_id=$user_id_from_search'>try to create this user</a>
    now.
    "
}


# ---------------------------------------------------------------
# Show Basic User Information (name & email)
# ---------------------------------------------------------------

# Define the column headers and column contents that 
# we want to show:
#

set ctr 1

set view_id [db_string select_view_id {}]

db_multirow -extend {col_name col_value} user_info user_info_sql {} {
    if {"" == $visible_for || [eval $visible_for]} {
	if {[expr $ctr % 2]} {
	    set td_class "class=rowodd"
	} else {
	    set td_class "class=roweven"
	}

        set cmd0 "set col_name $column_name"
        eval "$cmd0"
        regsub -all " " $col_name "_" col_name_subs
        set col_name [lang::message::lookup "" intranet-core.$col_name_subs $col_name]

	set cmd "set col_value $column_render_tcl"
	eval "$cmd"
	
	incr ctr
    }
}


set user_id $user_id_from_search


# ---------------------------------------------------------------
# Profile Management
# ---------------------------------------------------------------

set profile_component [im_profile::profile_component $user_id_from_search "disabled"]

# ------------------------------------------------------
# Show extension fields
# ------------------------------------------------------

set object_type "person"
set form_id "person_view"
set action_url "/intranet/users/new"
set form_mode "display"
set user_id $user_id_from_search

template::form create $form_id \
    -mode "display" \
    -display_buttons { }

# Find out all the groups of the user and map these
# groups to im_category "Intranet User Type"
set user_subtypes [im_user_subtypes $user_id]

im_dynfield::append_attributes_to_form \
    -object_subtype_id $user_subtypes \
    -object_type $object_type \
    -form_id $form_id \
    -object_id $user_id_from_search \
    -form_display_mode "display" \
    -page_url "/intranet/users/view"

