# -------------------------------------------------------------
# /packages/intranet-core/www/notifications/user-notifications.tcl
#
# Copyright (c) 2007 ]project-open[
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# Author: frank.bergmann@project-open.com
#

# -------------------------------------------------------------
# Variables:
#	user_id:integer
#	return_url

if {![info exists return_url] || "" == $return_url} { set return_url [im_url_with_query] }
if {0 == $user_id} { set user_id [ad_get_user_id] }
set current_user_id [ad_get_user_id]

if {$current_user_id != $user_id} { ad_return_template }

# Check the permissions
im_user_permissions $current_user_id $user_id view read write admin

set notification_object_id [apm_package_id_from_key "acs-workflow"]
set notification_delivery_method_id [notification::get_delivery_method_id -name "email"]
set notification_interval_id [notification::get_interval_id -name "instant"]

# ----------------------------------------------------
# Create a component to manage subscriptions

multirow create notifications url label title subscribed_p
set manage_url "[apm_package_url_from_key [notification::package_key]]manage"


# Old: "select short_name from notification_types where short_name like 'wf%'"

foreach type [db_list wf_notifs "select short_name from notification_types"] {
    set pretty_name [util_memoize [list db_string pretty_name "select pretty_name from notification_types where short_name = '$type'"]]
    set type_id [notification::type::get_type_id -short_name $type]
    
    set notification_subscribe_url [export_vars -base "/notifications/request-new?" {
	{object_id $notification_object_id} 
	{type_id $type_id}
	{delivery_method_id $notification_delivery_method_id}
	{interval_id $notification_interval_id}
	{"form\:id" "subscribe"}
	{formbutton\:ok "OK"}
	return_url
    }]
	
    # Check if subscribed
    set request_id [notification::request::get_request_id \
			-type_id $type_id \
			-object_id $notification_object_id \
			-user_id $user_id]
    
    set subscribed_p [expr ![empty_string_p $request_id]]
    
    if { $subscribed_p } {
	set url [notification::display::unsubscribe_url -request_id $request_id -url $return_url]
    } else {
	set url [notification::display::subscribe_url \
		     -type $type \
		     -object_id $notification_object_id \
		     -url $return_url \
		     -user_id $user_id \
		     -pretty_name $pretty_name]
	set url $notification_subscribe_url
    }
    
    if { ![empty_string_p $url] } {
	multirow append notifications \
	    $url \
	    [string totitle $pretty_name] \
	    [ad_decode $subscribed_p 1 "Unsubscribe from $pretty_name" "Subscribe to $pretty_name"] \
	    $subscribed_p
    }
}
