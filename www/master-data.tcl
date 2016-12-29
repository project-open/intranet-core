# /packages/intranet-core/www/master-data.tcl
#
# Copyright (C) 2003 - 2017 ]project-open[
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
    Master Data Page
    @author frank.bergmann@project-open.com
} {
    { plugin_id:integer "" }
}

# ---------------------------------------------------------------
# Security & Defaults
# ---------------------------------------------------------------

set current_user_id [auth::require_login]
set page_title  [lang::message::lookup "" intranet-core.Master_Data "Master Data"]
set page_focus "im_header_form.keywords"
set current_url [ns_conn url]
set header_stuff ""
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
set left_navbar_html ""


# ---------------------------------------------------------------------
# Show the list of object types and their objects
# ---------------------------------------------------------------------

set master_otypes {
    employee
    im_company
    im_conf_item
    im_cost_center
    im_component_plugin
    im_dynfield_attribute
    im_dynfield_widget
    im_indicator
    im_material
    im_menu
    im_office
    im_profile
    im_report
    im_rest_object_type
    im_rule
    im_ticket_queue
    person 
    survsimp_survey
    survsimp_question
    user 
}

set regular_otypes {
    im_project
    im_biz_object_group
    im_biz_object_member
    im_cost
    im_invoice
    im_expense
    im_expense_bundle
    im_expense_item
    im_repeating_cost
    im_risk
    im_sencha_preference
    im_ticket
    im_timesheet_task
    im_timesheet_conf_object
    im_timesheet_invoice
    im_user_absence
    survsimp_response
}

set rel_otypes {
    im_agile_task_rel
    relationship
    rel_segment
}

set openacs_otypes {
    application_group
    authority
    calendar
    cal_item
    group
    notification_interval
    notification_request
    notification_type
    notification_delivery_method
    site_node
}

set workflow_otypes {
    journal_entry
}

set url_hash(im_company) "/intranet/companies/index"
set url_hash(im_component_plugin) "/intranet/admin/components/index"
set url_hash(im_conf_item) "/intranet-confdb/index"
set url_hash(im_cost_center) "/intranet-cost/cost-centers/index"
set url_hash(im_dynfield_attribute) "/intranet-dynfield/index"
set url_hash(im_dynfield_widget) "/intranet-dynfield/widgets"
set url_hash(im_indicator) "/intranet-reporting-indicators/index"
set url_hash(im_menu) "/intranet/admin/menus/index"
set url_hash(im_material) "/intranet-material/index"
set url_hash(im_office) "/intranet/offices/index"
set url_hash(im_profile) "/admin/group-types/one?group_type=im_profile"
set url_hash(im_report) "/intranet-reporting/index"
set url_hash(im_rest_object_type) "/intranet-rest/index"
set url_hash(im_rule) "/intranet-rule-engine/index"
set url_hash(im_ticket_queue) "/admin/group-types/one?group_type=im_ticket_queue"
set url_hash(survsimp_survey) "/intranet-simple-survey/admin/index"
set url_hash(survsimp_question) "/intranet-simple-survey/admin/index"
set url_hash(user) "/intranet/users/index"


set sql "

select * from (
select	ot.object_type,
	ot.pretty_name,
	count(*) as cnt,
	CASE 
		WHEN ot.object_type in ('[join $master_otypes "','"]') THEN '0 - Master-data'
		WHEN ot.object_type in ('[join $regular_otypes "','"]') THEN '1 - Regular Objects'
		WHEN ot.object_type in ('[join $openacs_otypes "','"]') THEN '2 - OpenACS System Objects System Objects'
		WHEN ot.object_type like 'acs%' THEN '2 - OpenACS System Objects'
		WHEN ot.object_type like 'content_%' THEN '2 - OpenACS System Objects'
		WHEN ot.object_type like 'apm%' THEN '2 - OpenACS System Objects'
		WHEN ot.object_type like '::%' THEN '2 - OpenACS System Objects'
		WHEN ot.object_type like '%_rel' THEN '3 - Relationship Objects'
		WHEN ot.object_type in ('[join $rel_otypes "','"]') THEN '3 - Relationship Objects'
		WHEN ot.object_type in ('[join $workflow_otypes "','"]') THEN '8 - Workflows'
		WHEN ot.object_type like '%_wf' THEN '8 - Workflows'
		ELSE '9 - other'
	END as section
from	acs_objects o,
	acs_object_types ot
where	o.object_type = ot.object_type
group by ot.object_type
) t
where t.section = '0 - Master-data'
order by section, object_type
"
set last_section ""
db_multirow -extend {url} otypes otypes_query_query $sql {
    set url ""
    if {[info exists url_hash($object_type)]} { set url $url_hash($object_type) }
}



# ---------------------------------------------------------------
# Help message
#
set help_html [im_help_collapsible [lang::message::lookup "" intranet-core.Master_Date_Help "

<p>This page lists a number of object types that are used as master data,
together with their administration screen.
</p>
<p>Please click on the links below to get to the respective administration screens.</p>
"]]


# ---------------------------------------------------------------------
# Projects Submenu
# ---------------------------------------------------------------------

# Setup the subnavbar
set bind_vars [ns_set create]
set parent_menu_id [im_menu_id_from_label "master_data"]
set menu_label "master_data"
set sub_navbar [im_sub_navbar \
		    -components \
		    -current_plugin_id $plugin_id \
		    -base_url "/intranet/master-data" \
		    -plugin_url "/intranet/master-data" \
		    $parent_menu_id \
		    $bind_vars "" "pagedesriptionbar" $menu_label] 

set show_context_help_p 0

