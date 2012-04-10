# /packages/intranet-core/www/admin/views/new-column.tcl
#
# Copyright (C) 2003-2004 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Create a new view or edit an existing one.

    @param form_mode edit or display

    @author juanjoruizx@yahoo.es
} {
    {view_id ""}
    column_id:integer,optional
    edit_p:optional
    message:optional
    { form_mode "display" }
    { return_url "" }
}


# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set action_url "/intranet/admin/views/new-column"
set focus "column.column_name"


if {"" == $return_url} { set return_url [export_vars -base "/intranet/admin/views/new" {view_id}] }

if {"" == $view_id && [info exists column_id]} {
    set view_id [db_string vid "select view_id from im_view_columns where column_id = :column_id" -default ""]
}
if {"" == $view_id} {
    ad_return_complaint 1 "You need to specify view_id"
}

if {![info exists column_id]} { set form_mode "edit" }


set view_url [export_vars -base "/intranet/admin/views/new" {view_id}]
set view_name [db_list view_name "select view_name from im_views where view_id = :view_id"]
set view_link "<a href=$view_url>$view_name</a>"
set page_header [lang::message::lookup "" intranet-core.New_column "New Column"]
set page_title [lang::message::lookup "" intranet-core.New_column_for_view "New Column for View %view_link%"]
set context $page_title


# ad_return_complaint 1 "xxx: $return_url"

# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------


ad_form \
    -name column \
    -cancel_url $return_url \
    -action $action_url \
    -mode $form_mode \
    -method GET \
    -export {view_id return_url} \
    -form {
	column_id:key(im_view_columns_seq)
	{column_name:text(text) {label #intranet-core.Column_Name#} }
	{sort_order:integer(text) {label #intranet-core.Sort_Order#} {html {size 10 maxlength 15}}}
	{column_render_tcl:text(textarea),optional {label #intranet-core.Column_render_tcl#} {html {cols 50 rows 5}}}
	{extra_select:text(textarea),optional {label "Extra Select"} {html {cols 50 rows 5}}}
	{extra_from:text(textarea),optional {label #intranet-core.Extra_from#} {html {cols 50 rows 5}}}
	{extra_where:text(textarea),optional {label #intranet-core.Extra_where#} {html {cols 50 rows 5}}}
	{order_by_clause:text(textarea),optional {label #intranet-core.Order_by_clause#} {html {cols 50 rows 5}}}
	{visible_for:text(textarea),optional {label "Visible For"} {html {cols 50 rows 5}}}
	{ajax_configuration:text(textarea),optional {label "Ajax Configuration"} {html {cols 50 rows 5}}}
    }


ad_form -extend -name column -on_request {
    # Populate elements from local variables
    

} -select_query {

	select	vc.*
	from	IM_VIEW_COLUMNS vc
	where	vc.column_id = :column_id
		and vc.view_id = :view_id

} -validate {

        {column_name
            {![db_string unique_name_check "
		select count(*) 
		from im_view_columns 
                where	column_name = :column_name 
			and view_id = :view_id 
			and column_id != :column_id"]
	}
            "Duplicate column Name. Please use a new name."
        }

} -new_data {

    db_dml column_insert "
    insert into IM_VIEW_COLUMNS
	(column_id, view_id, column_name, 
	column_render_tcl, extra_select, extra_from, 
	extra_where, sort_order, order_by_clause,
	visible_for, ajax_configuration
    ) values (
	:column_id, :view_id, :column_name, 
	:column_render_tcl, :extra_select, :extra_from, 
	:extra_where, :sort_order, :order_by_clause,
	:visible_for, :ajax_configuration
    )"

} -edit_data {

    db_dml column_update "
	update IM_VIEW_COLUMNS set
	        column_name		= :column_name,
	        column_render_tcl	= :column_render_tcl,
	        extra_select		= :extra_select,
	        extra_from		= :extra_from,
	        extra_where		= :extra_where,
	        sort_order		= :sort_order,
	        order_by_clause		= :order_by_clause,
		visible_for		= :visible_for,
		ajax_configuration	= :ajax_configuration
	where
		column_id = :column_id
		and view_id = :view_id
"
} -on_submit {

	ns_log Notice "new1: on_submit"


} -after_submit {

    # Flush cache
    im_permission_flush

    ad_returnredirect $return_url
    ad_script_abort
}

