# /packages/intranet-core/tcl/intranet-sencha-procs.tcl
#
# Copyright (C) 1998-2004 various parties
# The code is based on ArsDigita ACS 3.4
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

ad_library {
    Interface for Sencha components.
    @author frank.bergmann@project-open.com
}

ad_proc -public im_sencha_extjs_installed_p { 
} {
    Returns 1 if a Senca ExtJS library is installed or 0 otherwise.
} {
    return [db_string im_package_core_id "
	select	count(*)
	from	apm_packages
	where	package_key like 'sencha-extjs-v%'
    " -default 0]
}

ad_proc -public im_sencha_extjs_version {
} {
    Returns a list with 1. the version number of the Sencha 
    library, 2. a value {dev|prod} indicating whether it
    is a development or a production version and 3. the 
    package key where the library is defined. An empty string
    indicates that no Sencha library is installed.<br>
    <ul>
    <li>sencha-extjs-v421 - {v421 prod sencha-extjs-v421} (production version of Sencha 4.2.1)
    <li>sencha-extjs-v422-dev - {v422 dev sencha-extjs-v422-dev} (development version of Sencha 4.2.2)
    </ul>
} {
    set sencha_package [db_string im_package_core_id "
      select  max(package_key)
      from    apm_packages
      where   package_key like 'sencha-extjs-v%'
    " -default ""]

    if {[regexp {^sencha-extjs-([0-9a-z]+)\-*(.*)$} $sencha_package match version type]} {
	if {"" == $type} { set type "prod" }
	return [list $version $type $sencha_package]
    }
    return [list]
}


ad_proc -public im_sencha_extjs_load_libraries {
    {-css_theme_folder "ext-all-gray.css"}
} {
    Instructs the OpenACS pages to load the right Sencha libraries
} {
    set extjs_version [im_sencha_extjs_version]

    if {"" == $extjs_version} { return "" }
    set version [lindex $extjs_version 0]
    set type [lindex $extjs_version 1]
    set package_key [lindex $extjs_version 2]

    switch $type {
	prod { set ext "ext-all.js" }
	dev { set ext "ext-all-debug-w-comments.js" }
	default {
	    ad_return_complaint 1 "<b>[lang::message::lookup "" intranet-core.Unknown_Sencha_Type "Unknown type of Sencha libraries: '%type%'"]</b>:<br>&nbsp;<br>
	    [lang::message::lookup "" intranet-core.Unknown_Sencha_Type_msg "Please contact your System Administrator"]"
	}
    } 

    # Fallback 
    if { ![file exists "[acs_package_root_dir $package_key]/www/resources/css/$css_theme_folder"] } {
	set css_theme_folder "ext-all.css"
    }

    # Instruct the page to add libraries
    template::head::add_css -href "/$package_key/resources/css/$css_theme_folder" -media "screen" -order 1
    template::head::add_javascript -src "/$package_key/$ext" -order 2
}

