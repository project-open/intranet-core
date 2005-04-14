ad_page_contract {
    Modify basic read/write/create/admin permissions for
    an arbitrary object.

    This is a modified copy of /packages/acs-subsite/www/admin/permissions.tcl
    with modification to adapt it to the needs of P/O.
    
    @author Lars Pind (lars@collaboraid.biz)
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 2003-06-13
    @cvs-id $Id$
} {
    object_id:integer,optional
}

set page_title "[ad_conn instance_name] Permissions"

set context [list "Permissions"]

if {![info exists object_id]} {
    set object_id [ad_conn subsite_id]
}
