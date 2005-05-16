# /packages/intranet-core/www/admin/profiles/new.tcl

ad_page_contract {

    Adds a new profile

    @author mbryzek@arsdigita.com
    @author frank.bergmann@project-open.com

} {
    { group_type "im_profile" }
    { group_type_exact_p t }
    { group_name "" }
    { group_id:naturalnum "" }
    {add_with_rel_type "composition_rel"}
    { return_url "" }
    {group_rel_type_list ""}
} 

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]">
    return
}

set context [list [list "[ad_conn package_url]admin/groups/" "Groups"] "Add a group"]

db_1row select_type_info {
    select t.pretty_name as group_type_pretty_name,
           t.table_name
      from acs_object_types t
     where t.object_type = :group_type
}

set export_var_list [list group_id group_type add_with_rel_type return_url]

template::form create add_group

attribute::add_form_elements -form_id add_group -start_with group -object_type $group_type

if { [template::form is_request add_group] } {
    
    foreach var $export_var_list {
	template::element create add_group $var \
		-value [set $var] \
		-datatype text \
		-widget hidden
    }

    # Set the object id for the new group
    template::element set_properties add_group group_id \
	    -value [db_nextval "acs_object_id_seq"]

}

if { [template::form is_valid add_group] } {

    im_exec_dml new_profile "im_create_profile(:group_name, 'profile')"

    # Add the original return_url as the last one in the list
    lappend return_url_list $return_url

    set return_url_stacked [subsite::util::return_url_stack $return_url_list]

    ad_returnredirect $return_url_stacked
    ad_script_abort
}


ad_return_template

