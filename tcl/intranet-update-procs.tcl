# /packages/intranet-core/tcl/intranet-update-procs.tcl
#
# Copyright (c) 2008 ]project-open[
# All rights reserved.
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
    Update procedures to deal with issues of APM upgrade.

    @author frank.bergmann@project-open.com
}

# -------------------------------------------------------------------
# Check for updates
# -------------------------------------------------------------------

ad_proc -public im_check_for_update_scripts {
} {
    Displays a warning to a user of the system needs to run
    update scripts.
    Returns a string suitable to be displayed to the user in
    a im_table_with_header component
} {
    # ---------------------------------------------------------------------------
    # Permissions - show only to Admin
    set user_admin_p [im_is_user_site_wide_or_intranet_admin [ad_get_user_id]]
    if {!$user_admin_p} { return "" }


    # ---------------------------------------------------------------------------
    # 0 - Check if the package "acs-workflow" is mounted at /workflow/
    # If this is the case then silently remount the package at /acs-workflow/
    # in oder to allow the "Workflow" package to mount at /workflow/.
    #
    set workflow_remount_p [db_string workflow_remount "
	select	count(*)
	from	site_nodes sn,
		apm_packages ap
	where
		sn.object_id = ap.package_id and
		sn.name = 'workflow' and
		ap.package_key = 'acs-workflow'
    "]

    if {$workflow_remount_p} {
	db_dml update_workflow_mount_point "
		update site_nodes set
			name = 'acs-workflow'
		where
			object_id = (
				select	package_id
				from	apm_packages
				where	package_key = 'acs-workflow'
			)
	"
    }

    # ---------------------------------------------------------------------------
    # 1 - Make sure base modules are installed

    # The base modules that need to be installed first
    set base_modules [list workflow notifications acs-datetime acs-workflow acs-mail-lite acs-events]

    set url "/acs-admin/apm/packages-install?update_only_p=1"
    set redirect_p 0
    set missing_modules [list]
    foreach module $base_modules {

#        ns_log Notice "upgrade1: checking module $module"
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

#        ns_log Notice "upgrade2: checking module $module"
        set spec_file "[acs_root_dir]/packages/$module/$module.info"

        set needs_update_p 0
        catch {
            array set version_hash [apm_read_package_info_file $spec_file]
            set version $version_hash(name)
            set needs_update_p [apm_higher_version_installed_p $module $version]
        }

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
    set ctr 0
    foreach module $other_modules {

	# Limit the number of packages to a value that doesn't give 
	# trouble with the URL size
	if {$ctr > 15} { continue }

        set spec_file "[acs_root_dir]/packages/$module/$module.info"

        set needs_update_p 0
        catch {
            array set version_hash [apm_read_package_info_file $spec_file]
            set version $version_hash(name)
            catch {[set needs_update_p [apm_higher_version_installed_p $module $version]]}
        }

        if {1 == $needs_update_p} {
            set redirect_p 1
            append url "enable=$module&"
            lappend missing_modules $module
        }
	incr ctr
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

#        ns_log Notice "upgrade4: checking glob file $dir"

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
        select  distinct l.log_key
        from    acs_logs l
        order by log_key
    "
    db_foreach db_files $sql {

#        ns_log Notice "upgrade4: checking log key $log_key"
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

    # Sort the list so the upgrade scripts are executed in rising order.
    set missing_modules [lsort $missing_modules]

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
		<nobr>
                [join $missing_modules "</nobr><br>\n<nobr>"]
		</nobr>
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
        from    apm_package_versions
        where   enabled_p = 't'
    "
    db_foreach packages $package_sql {

#        ns_log Notice "upgrade5: checking package $package_key"
        set core_upgrade_dir "$core_dir/$package_key/sql/postgresql/upgrade"
        foreach dir [lsort [glob -type f -nocomplain "$core_upgrade_dir/upgrade-?.?.?.?.?-?.?.?.?.?.sql"]] {

#            ns_log Notice "upgrade5: checking glob file $dir"

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
        select  distinct l.log_key
        from    acs_logs l
        order by log_key
    "
    db_foreach db_files $sql {

#        ns_log Notice "upgrade4: checking log key $log_key"
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

    # Sort the list so the upgrade scripts are executed in rising order.
    set missing_modules [lsort $missing_modules]

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
		<nobr>
                [join $missing_modules "</nobr><br>\n<nobr>"]
		</nobr>
        "
        return $upgrade_message
    }

    return ""
}



ad_proc -public im_update_package {
    { -package_key "" }
} {
    Run all update scripts of a specific package
} {
    set path "[acs_root_dir]/packages/$package_key"
    set find_cmd [im_filestorage_find_cmd]

    if {[catch {
        set file_list [exec $find_cmd $path -type f]
    } err_msg]} {
	ad_return_complaint 1 "Error executing 'exec find $path -name '*.sql'':<br>
        <pre>$err_msg</pre>"
	ad_script_abort
    }

    set sql_files [list]
    foreach file $file_list {
	if {![regexp {\.sql$} $file match]} { continue }
	if {![regexp {/upgrade/upgrade} $file match]} { continue }
	if {![regexp {/intranet\-} $file match]} { continue }
	if {![regexp {postgresql} $file match]} { continue }
	if {[regexp {CVS} $file match]} { continue }

	set key ""
	if {[regexp {(upgrade-.*\.sql)} $file match key]} {
	    lappend sql_files [list $file $key]
	}
    }

    set sorted_sql_files [qsort $sql_files [lambda {s} { lindex $s 1 }]]

    ad_return_complaint 1 $sorted_sql_files

    set file "[acs_root_dir]/packages/intranet-core/sql/postgresql/upgrade/upgrade-3.4.0.0.0-3.4.0.1.0.sql"
    db_source_sql_file $file
}
