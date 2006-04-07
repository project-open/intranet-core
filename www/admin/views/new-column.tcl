# /packages/intranet-core/www/admin/views/new-column.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Create a new view or edit an existing one.

    @param form_mode edit or display

    @author juanjoruizx@yahoo.es
} {
	view_id:notnull
    column_id:integer,optional
    return_url
    edit_p:optional
    message:optional
    { form_mode "display" }
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

set action_url ""
set focus "column.column_name"
set page_title "[_ intranet-core.New_column]"
set context $page_title

if {![info exists column_id]} { set form_mode "edit" }


# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------


ad_form \
    -name column \
    -cancel_url $return_url \
    -action $action_url \
    -mode $form_mode \
    -export {user_id view_id return_url} \
    -form {
		column_id:key(im_view_columns_seq)
		{column_name:text(text) {label #intranet-core.Column_Name#} }
		{sort_order:integer(text) {label #intranet-core.Sort_Order#} {html {size 10 maxlength 15}}}
		{column_render_tcl:text(textarea),optional {label #intranet-core.Column_render_tcl#} {html {cols 50 rows 5}}}
		{extra_select:text(textarea),optional {label #intranet-core.Column_sql#} {html {cols 50 rows 5}}}
		{extra_from:text(textarea),optional {label #intranet-core.Extra_from#} {html {cols 50 rows 5}}}
		{extra_where:text(textarea),optional {label #intranet-core.Extra_where#} {html {cols 50 rows 5}}}
		{order_by_clause:text(textarea),optional {label #intranet-core.Order_by_clause#} {html {cols 50 rows 5}}}
    }


ad_form -extend -name column -on_request {
    # Populate elements from local variables
    

} -select_query {

	select	vc.column_id,
			vc.column_name,
			vc.column_render_tcl,
			vc.extra_select,
			vc.extra_from,
			vc.extra_where,
			vc.sort_order,
			vc.order_by_clause
	from	IM_VIEW_COLUMNS vc
	where	vc.column_id = :column_id
	and		vc.view_id = :view_id

} -validate {

        {column_name
            {![db_string unique_name_check "select count(*) from im_view_columns 
                                            where column_name = :column_name and view_id = :view_id and column_id != :column_id"]}
            "Duplicate column Name. Please use a new name."
        }

} -new_data {

    db_dml column_insert "
    insert into IM_VIEW_COLUMNS
    (column_id, view_id, column_name, column_render_tcl, extra_select, extra_from, extra_where, sort_order, order_by_clause)
    values
    (:column_id, :view_id, :column_name, :column_render_tcl, :extra_select, :extra_from, :extra_where, :sort_order, :order_by_clause)
    "

} -edit_data {

    db_dml column_update "
	update IM_VIEW_COLUMNS set
	        column_name    = :column_name,
	        column_render_tcl  = :column_render_tcl,
	        extra_select    = :extra_select,
	        extra_from    = :extra_from,
	        extra_where		= :extra_where,
	        sort_order      = :sort_order,
	        order_by_clause  = :order_by_clause
	where
		column_id = :column_id
		and view_id = :view_id
"
} -on_submit {

	ns_log Notice "new1: on_submit"


} -after_submit {

	ad_returnredirect $return_url
	ad_script_abort
}


#      (select population_id, area_id, sum(gdp) from country_fact group by population_id, area_id)
#union (select population_id, null,    sum(gdp) from country_fact group by population_id);
