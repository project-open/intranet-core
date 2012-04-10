# /packages/intranet-core/www/admin/views/new.tcl
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
    view_id:integer,optional
    edit_p:optional
    message:optional
    { form_mode "display" }
    { return_url "" }
}


# ad_return_complaint 1 $return_url

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
set focus "view.view_name"
set page_title "[_ intranet-core.New_view]"
set context $page_title
set current_url $return_url
if {"" == $return_url} { set return_url [im_url_with_query] }


if {![info exists view_id]} { set form_mode "edit" }


# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------


ad_form \
    -name view \
    -cancel_url $return_url \
    -action $action_url \
    -mode $form_mode \
    -export {return_url} \
    -form {
	view_id:key(im_views_seq)
	{view_name:text(text) {label #intranet-core.View_Name#} }
	{view_type_id:text(im_category_tree),optional {label #intranet-core.View_Type#} {custom {category_type "Intranet DynView Type"}} {value ""} }
	{view_status_id:text(im_category_tree),optional {label #intranet-core.View_Status#} {custom {category_type "Intranet DynView Status"}} {value ""} }
	{sort_order:integer(text),optional {label #intranet-core.Sort_Order#} {html {size 10 maxlength 15}}}
	{view_sql:text(textarea),optional {label #intranet-core.View_sql#} {html {cols 50 rows 5}}}
    }


ad_form -extend -name view -on_request {
    # Populate elements from local variables
    

} -select_query {

	select	v.*
	from	im_views v
	where	v.view_id = :view_id

} -validate {

        {view_name
            {![db_string unique_name_check "
		select count(*)
		from im_views 
		where
			view_name = :view_name 
			and view_id != :view_id"]
	    }
            "Duplicate View Name. Please use a new name."
        }

} -new_data {

    db_dml view_insert "
    insert into IM_VIEWS
    (view_id, view_name, view_status_id, view_type_id, sort_order, view_sql)
    values
    (:view_id, :view_name, :view_status_id, :view_type_id, :sort_order, :view_sql)
    "

} -edit_data {

    db_dml view_update "
	update im_views set
	        view_name    = :view_name,
	        view_status_id  = :view_status_id,
	        view_type_id    = :view_type_id,
	        sort_order      = :sort_order,
	        view_sql  = :view_sql
	where
		view_id = :view_id
"
} -on_submit {

	ns_log Notice "new1: on_submit"


} -after_submit {

        # Flush permissions
        im_permission_flush

	# Redirect
	ad_returnredirect $return_url
	ad_script_abort
}


# ------------------------------------------------------
# List creation
# ------------------------------------------------------

if { [exists_and_not_null view_id] } {
	set action_list [list [_ intranet-core.Add_new_Column] [export_vars -base "new-column" {view_id return_url}] [_ intranet-core.Add_new_Column]]

	set elements_list {
	  column_id {
		label "[_ intranet-core.Column_Id]"
	  }
	  column_name {
		label "[_ intranet-core.Column_Name]"
		display_template {
			<a href="@columns.column_url@">@columns.column_name@</a>
		}
	  }
	  group_id {
		label "[_ intranet-core.Group_Id]"
	  }
	  sort_order {
		label "[_ intranet-core.Sort_Order]"
	  }
	  attrib_del {
	  	label ""
		display_template {
			<a href="@columns.del_column_url@">#intranet-core.Delete#</a>
		}
	  }
	}

	list::create \
		-name column_list \
		-multirow columns \
		-key column_id \
		-actions $action_list \
		-elements $elements_list \
		-filters { }

	db_multirow -extend {column_url del_column_url} columns get_columns { 
		select vc.*
		from im_view_columns vc
		where vc.view_id = :view_id
		order by vc.sort_order
	} {
		set column_url [export_vars -base "new-column" {view_id column_id return_url}]
		set del_column_url [export_vars -base "del-column" {view_id column_id return_url}]
	}
}