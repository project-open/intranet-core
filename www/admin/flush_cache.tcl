# /packages/intranet-filestorage/www/index.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.

ad_page_contract {
    Show the list of current task and allow the project
    manager to create new tasks.

    @author fraber@project-open.com
    @creation-date Nov 2003
} {
    { return_url ""}
}

if {"" == $return_url} {
    set return_url "/intranet/admin/"
}

# Remove all permission related entries in the system cache
im_permission_flush

db_release_unused_handles
ad_returnredirect $return_url



