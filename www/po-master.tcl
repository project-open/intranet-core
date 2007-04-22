# Expects properties:
#   title
#   focus
#   header_stuff
#   section

if { ![info exists section] } {
    set section {}
}

if { ![info exists title] } {
    set title "Project/Open"
}

if { ![info exists header_stuff] } {
    set header_stuff {}
}

if { ![info exists focus] } {
    set focus {}
}

if { [template::util::is_nil subnavbar_link] } {
    set subnavbar_link ""
}

# This will set 'sections' and 'subsections' multirows
subsite::define_pageflow -section $section
subsite::get_section_info -array section_info

# Find the subsite we belong to
set subsite_url [site_node_closest_ancestor_package_url]
array set subsite_sitenode [site_node::get -url $subsite_url]
set subsite_node_id $subsite_sitenode(node_id)
set subsite_name $subsite_sitenode(instance_name)

# Where to find the stylesheet
set css_url "/resources/acs-subsite/site-master.css"

# Get system name
set system_name [ad_system_name]
set system_url [ad_url]
if { [string equal [ad_conn url] "/"] } {
    set system_url ""
}

# Get user information
set sw_admin_p 0
set user_id [ad_conn user_id]
set untrusted_user_id [ad_conn untrusted_user_id]
if { $untrusted_user_id != 0 } {
    set user_name [person::name -person_id $untrusted_user_id]
    set pvt_home_url [ad_pvt_home]
    set pvt_home_name [ad_pvt_home_name]
    if [empty_string_p $pvt_home_name] {
	set pvt_home_name [_ acs-subsite.Your_Account]
    }
    set logout_url [ad_get_logout_url]

    # Site-wide admin link
    set admin_url {}

    set sw_admin_p [acs_user::site_wide_admin_p -user_id $untrusted_user_id]

    if { $sw_admin_p } {
        set admin_url "/acs-admin/"
        set devhome_url "/acs-admin/developer"
        set locale_admin_url "/acs-lang/admin"
    } else {
        set subsite_admin_p [permission::permission_p \
                                 -object_id [subsite::get_element -element object_id] \
                                 -privilege admin \
                                 -party_id $untrusted_user_id]

        if { $subsite_admin_p  } {
            set admin_url "[subsite::get_element -element url]admin/"
        }
    }
} 

if { $untrusted_user_id == 0 } {
    set login_url [ad_get_login_url -return]
}

# Context bar
if { [info exists context] } {
    set context_tmp $context
    unset context
} else {
    set context_tmp {}
}
ad_context_bar_multirow -- $context_tmp


# change locale
set num_of_locales [llength [lang::system::get_locales]]
if { $num_of_locales > 1 } {
    set change_locale_url \
        "/acs-lang/?[export_vars { { package_id "[ad_conn package_id]" } }]"
}

# Curriculum bar
set curriculum_bar_p [util_memoize [list llength [site_node::get_children -all -filters { package_key "curriculum" } -node_id $subsite_node_id]]]


# Who's Online
set num_users_online [lc_numeric [whos_online::num_users]]

set whos_online_url "[subsite::get_element -element url]shared/whos-online"


#----------------------------------------------------------------------
# Display user messages
#----------------------------------------------------------------------

util_get_user_messages -multirow "user_messages"



# HAM : lets check ajaxhelper globals ***********************

global ajax_helper_js_sources
global ajax_helper_yui_js_sources
global ajax_helper_dojo_js_sources
set js_sources ""

if { [info exists ajax_helper_js_sources] || [info exists ajax_helper_yui_js_sources] || [info exists ajax_helper_dojo_js_sources] } {

    # if we're using ajax, let's use doc_type strict so we can get
    # consistent results accross standards compliant browsers
    set doc_type { <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"> }

    if { [info exists ajax_helper_js_sources] } {
	append js_sources [ah::load_js_sources -source_list $ajax_helper_js_sources]
    }

    if { [info exists ajax_helper_yui_js_sources] } {
	append js_sources [ah::yui::load_js_sources -source_list $ajax_helper_yui_js_sources]
    }

    if { [info exists ajax_helper_dojo_js_sources] } {
	append js_sources [ah::dojo::load_js_sources -source_list $ajax_helper_dojo_js_sources]
    }
}

# ***********************************************************

set extra_stuff_for_document_head "$js_sources"
if { ![exists_and_not_null extra_stuff_for_document_head] } {
    set extra_stuff_for_document_head [ad_partner_upvar extra_stuff_for_document_head]
}

append extra_stuff_for_document_head [im_stylesheet]
append extra_stuff_for_document_head "<script src=\"/resources/acs-subsite/core.js\" language=\"javascript\"></script>\n"
append extra_stuff_for_document_head "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">\n"
append extra_stuff_for_document_head "<script src=\"/intranet/js/showhide.js\" language=\"javascript\"></script>\n"
append extra_stuff_for_document_head "<!--\[if lt IE 7.\]>\n<script defer type='text/javascript' src='/intranet/js/pngfix.js'></script>\n<!\[endif\]-->\n"

if {[llength [info procs im_amberjack_header_stuff]]} {
    append extra_stuff_for_document_head [im_amberjack_header_stuff]
}

set extra_stuff_for_body "onLoad=\"javascript:initPortlet();\" "
if { [empty_string_p $extra_stuff_for_document_head] } {
    set extra_stuff_for_document_head [ad_partner_upvar extra_stuff_for_document_head]
}

append extra_stuff_for_document_head [im_stylesheet]
append extra_stuff_for_document_head "<script src=\"/resources/acs-subsite/core.js\" language=\"javascript\"></script>\n"
append extra_stuff_for_document_head "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">\n"
append extra_stuff_for_document_head "<script src=\"/intranet/js/showhide.js\" language=\"javascript\"></script>\n"
append extra_stuff_for_document_head "<!--\[if lt IE 7.\]>\n<script defer type='text/javascript' src='/intranet/js/pngfix.js'></script>\n<!\[endif\]-->\n"

if {[llength [info procs im_amberjack_header_stuff]]} {
    append extra_stuff_for_document_head [im_amberjack_header_stuff]
}

append extra_stuff_for_document_head $header_stuff
set extra_stuff_for_body [list [list onLoad "javascript:initPortlet();"]]
