# /packages/intranet-core/tcl/intranet-update-procs.tcl
#
# Copyright (C) 1998-2008 ]project-open[
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
    Checks if updates are necessary and shows updates in home and admin page

    @author frank.bergmann@project-open.com
}

# -------------------------------------------------------------------
# Check for updates
# -------------------------------------------------------------------

ad_proc -public im_check_for_updates {
} {
    Displays a warning to a user of the system needs to run
    update scripts.
} {

    # ---------------------------------------------------------------------------
    # 1 - Make sure base modules are installed

    # The base modules that need to be installed first
    set base_modules [list workflow notifications acs-datetime acs-workflow acs-mail-lite acs-events]

    set url "/acs-admin/apm/packages-install?update_only_p=1"
    set redirect_p 0
    set missing_modules [list]
    foreach module $base_modules {

	ns_log Notice "upgrade1: checking module $module"
	set installed_p [db_string notif "select count(*) from apm_package_versions where package_key = :module"]
	if {!$installed_p} { 
	    set redirect_p 1
	    lappend missing_modules $module
	}
    }

    if {$redirect_p} {
	set upgrade_message "
		<b>Important packages missing:</b><br>
		We found that your system lacks important packages.<br>
		Please click on the link below to install these packages now.<br>
		<br>&nbsp;<br>
		<a href=$url>Install packages</a> ([join $missing_modules ", "])
		<br>&nbsp;<br>
		<font color=red><b>Please don't forget to restart the server after install.</b></font>
	"
	return $upgrade_message
    }


    # ---------------------------------------------------------------------------
    # 2 - Update intranet-dynfield & intranet-core

    # The base modules that need to be installed first
    set core_modules [list intranet-core]

    set url "/acs-admin/apm/packages-install-2?"
    set redirect_p 0
    set missing_modules [list]
    foreach module $core_modules {

	ns_log Notice "upgrade2: checking module $module"
	set spec_file "[acs_root_dir]/packages/$module/$module.info"
	array set version_hash [apm_read_package_info_file $spec_file]
	set version $version_hash(name)
	set needs_update_p [apm_higher_version_installed_p $module $version]

	if {1 == $needs_update_p} { 
	    set redirect_p 1
	    append url "enable=$module&"
	    lappend missing_modules $module
	}
    }

    if {$redirect_p} {
	set upgrade_message "
		<b>Update the 'Core' modules:</b><br>
		The 'core' modules (intranet-core and intranet-dynfield) need to be
		updated before other modules can be updated.<br>
		Please click on the link below to install these packages now.<br>
		<br>&nbsp;<br>
		<a href=$url>Install packages</a> ([join $missing_modules ", "])
		<br>&nbsp;<br>
		<font color=red><b>Please don't forget to restart the server after install.</b></font>
	"
	return $upgrade_message
    }


    # ---------------------------------------------------------------------------
    # 3 - Update the rest

    set other_modules [db_list modules "select distinct package_key from apm_package_versions"]

    set url "/acs-admin/apm/packages-install-2?"
    set redirect_p 0
    set missing_modules [list]
    foreach module $other_modules {

	ns_log Notice "upgrade3: checking module $module"
	set spec_file "[acs_root_dir]/packages/$module/$module.info"
	array set version_hash [apm_read_package_info_file $spec_file]
	set version $version_hash(name)
	set needs_update_p [apm_higher_version_installed_p $module $version]

	if {1 == $needs_update_p} { 
	    set redirect_p 1
	    append url "enable=$module&"
	    lappend missing_modules $module
	}
    }

    if {$redirect_p} {
	set upgrade_message "
		<b>Update other modules:</b><br>
		There are modules in the system that need to be updated
		in order to guarantee the proper working of the system.<br>
		Please click on the link below to install these packages now.<br>
		<br>&nbsp;<br>
		<a href=$url>Update packages</a> ([join $missing_modules ", "])
		<br>&nbsp;<br>
		<font color=red><b>Please don't forget to restart the server after install.</b></font>
	"
	return $upgrade_message
    }


    # ---------------------------------------------------------------------------
    # 4 - Check for non-executed "intranet-core" upgrade scripts


    # --------------------------------------------------------------
    # Get the list of upgrade scripts in the FS
    set missing_modules [list]
    set core_dir "[acs_root_dir]/packages/intranet-core"
    set core_upgrade_dir "$core_dir/sql/postgresql/upgrade"
    foreach dir [lsort [glob -type f -nocomplain "$core_upgrade_dir/upgrade-?.?.?.?.?-?.?.?.?.?.sql"]] {

	ns_log Notice "upgrade4: checking glob file $dir"

	# Skip upgrade scripts from 3.0.x
	if {[regexp {upgrade-3\.0.*\.sql} $dir match path]} { continue }

	# Add the "/packages/..." part to hash-array for fast comparison.
	if {[regexp {(/packages.*)} $dir match path]} {
	    set fs_files($path) $path
	}
    }

    # --------------------------------------------------------------
    # Get the upgrade scripts that were executed
    set sql "
	select	distinct l.log_key
	from	acs_logs l
	order by log_key
    "
    db_foreach db_files $sql {

	ns_log Notice "upgrade4: checking log key $log_key"
	# Add the "/packages/..." part to hash-array for fast comparison.
	if {[regexp {(/packages.*)} $log_key match path]} {
	    set db_files($path) $path
	}
    }

    # --------------------------------------------------------------
    # Check if there are scripts that weren't executed:
    set url "/acs-admin/apm/packages-install-2?"
    set requires_upgrade_p 0
    set form_vars ""
    foreach file [array names fs_files] {
	if {![info exists db_files($file)]} {
	    lappend missing_modules $file
	    append form_vars "<input type=hidden name=upgrade_script value=\"$file\">\n"
	    set requires_upgrade_p 1
	}
    }

    if {$requires_upgrade_p} {
	set upgrade_message "
		<b>Run Upgrade Scripts:</b><br>
		It seems that there are upgrade scripts in your system that
		have not yet been executed.<br>
		This situation may occur during or after an upgrade of 
		V3.1 - V3.3 and is usually not a big issue. 
		However, we recommend to run these upgrade scripts now.<br>
		Please click on the link below to run these scripts now.<br>
		<br>&nbsp;<br>
		<form action=/intranet/admin/install-upgrade-scripts method=POST>
		$form_vars
		<input type=submit value='Run Upgrade Scripts'>
		</form>
		<br>
		<p>
		<b>Here is the list of scripts to run</b>:<p>
		[join $missing_modules "<br>\n"]
	"
	return $upgrade_message
    }



    # ---------------------------------------------------------------------------
    # 5 - Check for non-executed other upgrade scripts


    # --------------------------------------------------------------
    # Get the list of upgrade scripts in the FS
    set missing_modules [list]
    set core_dir "[acs_root_dir]/packages"

    set package_sql "
	select distinct
		package_key
	from	apm_package_versions
	where	enabled_p = 't'
    "
    db_foreach packages $package_sql {

	ns_log Notice "upgrade5: checking package $package_key"
	set core_upgrade_dir "$core_dir/$package_key/sql/postgresql/upgrade"
	foreach dir [lsort [glob -type f -nocomplain "$core_upgrade_dir/upgrade-?.?.?.?.?-?.?.?.?.?.sql"]] {

	    ns_log Notice "upgrade5: checking glob file $dir"

	    # Skip upgrade scripts from 3.0.x
	    if {[regexp {upgrade-3\.0.*\.sql} $dir match path]} { continue }

	    # Add the "/packages/..." part to hash-array for fast comparison.
	    if {[regexp {(/packages.*)} $dir match path]} {
		set fs_files($path) $path
	    }
	}
    }


    # --------------------------------------------------------------
    # Get the upgrade scripts that were executed
    set sql "
	select	distinct l.log_key
	from	acs_logs l
	order by log_key
    "
    db_foreach db_files $sql {

	ns_log Notice "upgrade4: checking log key $log_key"
	# Add the "/packages/..." part to hash-array for fast comparison.
	if {[regexp {(/packages.*)} $log_key match path]} {
	    set db_files($path) $path
	}
    }

    # --------------------------------------------------------------
    # Check if there are scripts that weren't executed:
    set url "/acs-admin/apm/packages-install-2?"
    set requires_upgrade_p 0
    set form_vars ""
    foreach file [array names fs_files] {
	if {![info exists db_files($file)]} {
	    lappend missing_modules $file
	    append form_vars "<input type=hidden name=upgrade_script value=\"$file\">\n"
	    set requires_upgrade_p 1
	}
    }

    if {$requires_upgrade_p} {
	set upgrade_message "
		<b>Run Upgrade Scripts:</b><br>
		It seems that there are upgrade scripts in your system that
		have not yet been executed.<br>
		This situation may occur during or after an upgrade of 
		V3.1 - V3.3 and is usually not a big issue. 
		However, we recommend to run these upgrade scripts now.<br>
		Please click on the link below to run these scripts now.<br>
		<br>&nbsp;<br>
		<form action=/intranet/admin/install-upgrade-scripts method=POST>
		$form_vars
		<input type=submit value='Run Upgrade Scripts'>
		</form>
		<br>
		<p>
		<b>Here is the list of scripts to run</b>:<p>
		[join $missing_modules "<br>\n"]
	"
	return $upgrade_message
    }

    return ""
}

