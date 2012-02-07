# /packages/intranet-core/www/admin/templates/index.tcl
#
# Copyright (C) 2009 ]project-open[

ad_page_contract {
    Show the list of templates in the system
    @author frank.bergmann@project-open.com
} {
    { return_url "/intranet/admin/templates/index" }
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set page_title [lang::message::lookup "" intranet-core.Templates "Templates"]
set context_bar [im_context_bar $page_title]
set context ""
set find_cmd [parameter::get -package_id [im_package_core_id] -parameter "FindCmd" -default "/bin/find"]

set bgcolor(0) " class=rowodd"
set bgcolor(1) " class=roweven"


# ------------------------------------------------------
# Get the list of backup sets for restore
# ------------------------------------------------------

# Get the list of all backup sets under backup_path
set backup_path [im_backup_path]
set backup_path_exists_p [file exists $backup_path]
set not_backup_path_exists_p [expr !$backup_path_exists_p]


db_multirow -extend { object_attributes_url url } templates templates_sql {
	select	*
	from	im_categories
	where	category_type = 'Intranet Cost Template'
	order by
		lower(category)
} {
    set object_attributes_url ""
    set url "/intranet/admin/templates/template-download.tcl?template_name=$category"
}

template::list::create \
    -name templates \
    -key category_id \
    -elements {
	category {
	    label "Template Name"
	    link_url_col url
	}
	enabled_p {
	    label "Enabled?"
	}
    } \
    -bulk_actions { 
	"Enable Template" "template-enable" "Enable Template" 
	"Disable Template" "template-disable" "Disable Template" 
	"Delete Template" "template-delete" "Delete Template" 
    } \
    -bulk_action_method post \
    -bulk_action_export_vars { return_url } \
    -actions [list "Upload New Template" [export_vars -base template-upload] "Upload a new template"]

