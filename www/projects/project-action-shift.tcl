# /packages/intranet-core/www/project-action-shift.tcl
#
# Copyright (C) 2003-2013 ]project-open[
#
# All rights reserved. Please check
# https://www.project-open.com/license/ for details.

ad_page_contract {
    Move a project back or forth in time
    @author frank.bergmann@project-open.com
} {
    {select_project_id ""}
    {return_url "/intranet/admin/menus"}
}

set user_id [auth::require_login]

set page_title [lang::message::lookup "" intranet-core.Shift_Project "Shift Project"]
set left_navbar_html ""
set sub_navbar ""
set show_context_help_p 0
