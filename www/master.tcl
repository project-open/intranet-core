# /packages/intranet-core/www/master.tcl

if { ![info exists header_stuff] } { set header_stuff {} }
if { ![info exists title] } { set title {} }
if { ![info exists main_navbar_label] } { set main_navbar_label {} }
if { ![info exists sub_navbar] } { set sub_navbar {} }
if { ![info exists left_navbar] } { set left_navbar {} }
if { ![info exists show_left_navbar_p] } { set show_left_navbar_p 1 }
if { ![info exists show_context_help_p] } { set show_context_help_p 0 }

if { ![info exists feedback_message_key] } { set feedback_message_key {} }
if { ![info exists user_feedback_id] } { set user_feedback_id 0 }
if { ![info exists user_feedback_txt] } { set user_feedback_txt {} }
if { ![info exists user_feedback_type] } { set user_feedback_type {} }
if { ![info exists user_feedback_link] } { set user_feedback_link {} }

# ns_log Notice "master: show_left_navbar_p=$show_left_navbar_p"
# ns_log Notice "master: header_stuff=$header_stuff"

set show_navbar_p [parameter::get_from_package_key -package_key "intranet-core" -parameter "ShowLeftFunctionalMenupP" -default 0]

# Don't show navbar if explicitely disabled and for anonymous user (while logging in)
if {!$show_navbar_p && "" == [string trim $left_navbar]} { set show_left_navbar_p 0 }
if {0 == [ad_get_user_id]} { set show_left_navbar_p 0 }

# ----------------------------------------------------
# Admin Navbar
#
# Logic to show an Admin Navbar for OpenACS pages
# These pages don't explicitely set the Admin navbar.
# We want to show the Admin Navbar to create a unified
# feeling for SysAdmins.
#
if {"" == $sub_navbar} {
    # Get the current URL, split into pieces and remove first empty piece.
    set url [ns_conn url]
    set url_pieces [split $url "/"]
    set url_pieces [lrange $url_pieces 1 end]
    set url0 [lindex $url_pieces 0]
    set url1 [lindex $url_pieces 1]

    set label ""
    switch $url0 {

	acs-admin { 
	    switch $url1 {
		cache		{ set label "openacs_cache" }
		auth		{ set label "openacs_auth" }
		developer	{ set label "openacs_developer" }
		default		{ set label "openacs_developer" }
	    }
	}
	acs-lang { 
	    switch $url1 {
		default		{ set label "openacs_l10n" }
	    }
	}
	admin { 
	    switch $url1 {
		site-map	{ set label "openacs_sitemap" }
		default		{ set label "" }
	    }
	}
	api-doc			{ set label "openacs_api_doc" }
	ds { 
	    switch $url1 {
		shell		{ set label "openacs_shell" }
		default		{ set label "openacs_ds" }
	    }
	}
	intranet-exchange-rate	{ set label "admin_exchange_rates" }
	intranet-material	{ set label "material" }
	intranet-simple-survey	{ 
	    switch $url1 {
		admin		{ set label "admin_survsimp" }
		default		{ set label "" }
	    }
	}
	xowiki - documentation { 
	    set show_left_navbar_p 0
	}
    }

    if {"" != $label} {

	# Show a help link in the search bar
	set show_context_help_p 1

	set admin_navbar_label ""
	set parent_menu_id [util_memoize [list db_string admin_parent_menu "select menu_id from im_menus where label = 'admin'" -default 0]]

	# Moved the context help to the "search bar"
#	set sub_navbar [im_sub_navbar -show_help_icon $parent_menu_id "" $title "pagedesriptionbar" $label]
	set sub_navbar [im_sub_navbar $parent_menu_id "" $title "pagedesriptionbar" $label]

    }

}

if { "" != $feedback_message_key } {
    if { [lang::message::message_exists_p [lang::user::locale] $feedback_message_key] } {
	set user_feedback_txt [lang::message::lookup "" $feedback_message_key ""]
    } elseif { [lang::message::message_exists_p "en_US" $feedback_message_key]} {
	set user_feedback_txt [lang::message::lookup "en_US" $feedback_message_key ""]
    } else {
	set user_feedback_txt "Message Key missing: $feedback_message_key"
	if { [im_user_is_admin_p [ad_maybe_redirect_for_registration]] } {
		set package_key [string range $feedback_message_key 0 [expr [string first . $feedback_message_key]-1]] 		
		set message_key [string range $feedback_message_key [expr [string first . $feedback_message_key]+1] [string length $feedback_message_key]]
		set user_feedback_link "/acs-lang/admin/edit-localized-message?package_key=$package_key&locale=[lang::user::locale]&show=all&message_key=$message_key"
	} 
    }
}









