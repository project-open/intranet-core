# /packages/intranet-core/www/new-custselect.tcl
#
# Copyright (c) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    Determine the customer for a project, if it wasn't defined before.
    @author frank.bergmann@project-open.com
} {
    project_id:optional,integer
    { parent_id:integer "" }
    { company_id:integer "" }
    project_nr:optional
    { workflow_key "" }
    return_url
}

# ---------------------------------------------------------------
# Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
if {![im_permission $user_id add_projects]} {
    ad_return_complaint "Insufficient Privileges" "
    <li>You don't have sufficient privileges to see this page."    
}

# ---------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------

set page_title "[_ intranet-invoices.Select_Customer]"
set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-core.Projects]"] $page_title]


# ---------------------------------------------------------------
#
# ---------------------------------------------------------------


# Check of customer and provider are already set...
#
if {"" != $company_id} {
    ad_return_complaint 1 "There is already a 'company_id' specified.<br>
    This is very likely an internal error of the appplication".
    ad_script_abort
}

set customer_select [im_company_select company_id 0 "Active" "CustOrIntl"]
# set provider_select [im_company_select company_id 0 "" "Provider"]

db_release_unused_handles
