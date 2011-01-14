# -------------------------------------------------------------
# /packages/intranet-core/www/users/base-info-component.tcl
#
# Copyright (c) 2008 ]project-open[
# All rights reserved.
#
# Author: frank.bergmann@project-open.com
#

# -------------------------------------------------------------
# Variables:
#	user_id:integer
#	return_url

if {![info exists user_id]} {

    ad_page_contract {
	@author frank.bergmann@project-open.com
    } {
	user_id
    }

}

# ------------------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------------------

set td_class(0) "class=roweven"
set td_class(1) "class=rowodd"

if {"" == $user_id} { set user_id 0 }

if {![info exists return_url] || "" == $return_url} { set return_url [im_url_with_query] }
set current_user_id [ad_maybe_redirect_for_registration]

# Check the permissions
user_permissions $current_user_id $user_id view read write admin

# Moved into the .adp template
# if {!$read} { return "" }


# ------------------------------------------------------------------
# Base Information
# ------------------------------------------------------------------

set info_actions [list {"Edit" edit}]
set info_action_url [export_vars -base "/intranet/users/new" user_id]
ad_form \
    -name userinfo \
    -action $info_action_url \
    -actions $info_actions \
    -mode "display" \
    -export {next_url return_url} \
    -form {
	{user_id:key}
	{email:text(text) {label "[_ intranet-core.Email]"} {html {size 30}}}
	{first_names:text(text) {label "[_ intranet-core.First_names]"} {html {size 30}}}
	{last_name:text(text) {label "[_ intranet-core.Last_name]"} {html {size 30}}}
    } -select_query {

	select	u.*,
		p.*,
		pa.*
	from	users u,
		persons p,
		parties pa
	where	u.user_id = :user_id and
		p.person_id = u.user_id and
		pa.party_id = u.user_id

    }


# Find out all the groups of the user and map these
# groups to im_category "Intranet User Type"
set user_subtypes [im_user_subtypes $user_id]

# Append dynfields to the form
im_dynfield::append_attributes_to_form \
    -form_display_mode display \
    -object_subtype_id $user_subtypes \
    -object_type "person" \
    -form_id "userinfo" \
    -object_id $user_id \
    -page_url "/intranet/users/new"


# ------------------------------------------------------------------
# Contact information
# ------------------------------------------------------------------

db_1row user_info "
	select	u.*,
		p.*,
		pa.*,
		uc.*,
		im_name_from_user_id(u.user_id) as user_name_pretty,
		(select country_name from country_codes where iso = uc.ha_country_code) as ha_country_name,
		(select country_name from country_codes where iso = uc.wa_country_code) as wa_country_name
	from	
		persons p,
		parties pa,
		users u
		LEFT OUTER JOIN users_contact uc ON (u.user_id = uc.user_id)
	where	
		u.user_id = :user_id and
		p.person_id = u.user_id and
		pa.party_id = u.user_id
"

set view_id [db_string get_view_id "select view_id from im_views where view_name='user_contact'"]

set column_sql "
	select	column_name,
		column_render_tcl,
		visible_for
	from	im_view_columns
	where	view_id=:view_id
		and group_id is null
	order by sort_order
"

set contact_html "
<form method=POST action=/intranet/users/contact-edit>
[export_form_vars user_id return_url]
<table cellpadding=0 cellspacing=2 border=0 class=\"component_form\">
  <tr> 
    <td colspan=2 class=rowtitle align=center>[_ intranet-core.Contact_Information]</td>
  </tr>
"

set ctr 1
db_foreach column_list_sql $column_sql {
        if {"" == $visible_for || [eval $visible_for]} {
	    append contact_html "
            <tr>
            <td class=\"form_label\">"
            set cmd0 "append contact_html $column_name"
            eval "$cmd0"
            append contact_html " &nbsp;</td><td class=\"form_widget\">"
	    set cmd "append contact_html $column_render_tcl"
	    eval $cmd
	    append contact_html "</td></tr>\n"
            incr ctr
        }
}    
append contact_html "</table>\n</form>\n"


