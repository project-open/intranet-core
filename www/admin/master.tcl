# /packages/intranet-core/www/admin/master.tcl

if { ![info exists header_stuff] } { set header_stuff {} }
if { ![info exists title] } { set title {} }
if { ![info exists context] } { set context {} }
if { ![info exists left_navbar] } { set left_navbar {} }
if { ![info exists show_left_navbar_p] } { set show_left_navbar_p 1 }
if { ![info exists admin_navbar_label] } { set admin_navbar_label "" }
if { ![info exists show_context_help_p] } { set show_context_help_p 1 }

set parent_menu_id [im_menu_id_from_label "admin"]
set sub_navbar_html [im_sub_navbar $parent_menu_id "" $title "pagedesriptionbar" $admin_navbar_label]

