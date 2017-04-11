# /packages/intranet-core/tcl/intranet-system-procs.tcl
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
    System (operating system) related functions.
    @author frank.bergmann@project-open.com
}

# --------------------------------------------------------
# Wrapper for ]po[ specific logic for exec
# --------------------------------------------------------

ad_proc -public im_exec {args} {
    Wrapper for ]po[ specific logic for exec,
    particularly under Windows.
} {
    global tcl_platform
    set platform $tcl_platform(platform)
    #set platform "windows"

    ns_log Notice "im_exec: platform=$platform, args=$args"
    switch $platform {
	"windows" {return [im_exec_windows $args] }
	"unix" - "linux" {return [im_exec_linux $args] }
	default {return [im_exec_linux $args] }
    }
}

ad_proc -public im_exec_linux {args} {
    Linux - just execute args using "exec"
} {
    set args [lindex $args 0]
    set cmd [linsert $args 0 exec]
    ns_log Notice "im_exec_linux: cmd=$cmd"
    set result [eval $cmd]
    ns_log Notice "im_exec_linux: args=$args, result=$result"
    return $result
}


ad_proc -public im_exec_windows {args} {
    Windows spefic for exec, in order to translate to CygWin commands.
} {
    set args [lindex $args 0]
    ns_log Notice "im_exec_windows: args=$args"

    # Processing program name
    set procname [lindex $args 0]		;# /usr/bin/find or similar
    set procname [im_exec_windows_transform_procname $procname]
    set args [lrange $args 1 end]		;# other args to pass to procname
    ns_log Notice "im_exec_windows: procname=$procname, args=$args"

    # fraber 170409: ToDo: testing
    # Processing its arguments 
    #for {set i 0} {$i < [llength $args]} {incr i} {
    #    if {[string match [lindex $args $i] "2>/dev/null"]} {
    #        set args [lreplace $args $i $i "2>nul"]
    #    }
    #}

    # Call the original exec
    set cmd [linsert $args 0 $procname]
    set cmd [linsert $cmd 0 "exec"]
    ns_log Notice "im_exec_windows: cmd=$cmd"
    set result [eval $cmd]
    ns_log Notice "im_exec_windows: cmd=$cmd -> $result"
    return $result
}


ad_proc -public im_exec_windows_transform_procname {procname} {
    Robust routine to convert any reasonable Linux command with
    or without absolute pathes into a CygWin command
} {
    return [im_exec_windows_transform_procname_helper $procname]
    #return [util_memoize [list im_exec_windows_transform_procname_helper $procname]]
}


ad_proc -public im_exec_windows_transform_procname_helper {procname} {
    Robust routine to convert any reasonable Linux command with
    or without absolute pathes into a CygWin command
} {
    # Does the file exist with that path? Then just return...
    if {[file exists $procname]} { return $procname }

    # Processing program name
    set procname [file tail $procname]		;# remove leading /.../.../ crud
    set unixaoldir [im_exec_windows_aoldir]	;# c:/project-open or similar

    # CygWin keeps all commands in /bin...
    set file "${unixaoldir}/bin/${procname}"
    if {[file exists $file.exe]} { return $file }
    if {[file exists $file.bat]} { return $file }

    # PostgreSQL binaries in /pgsql/bin
    set file "${unixaoldir}/pgsql/bin/${procname}"
    if {[file exists $file.exe]} { return $file }
    if {[file exists $file.bat]} { return $file }

    return $procname
}


ad_proc -public im_exec_windows_aoldir {} {
    Returns the base directory in Windows, something like "c:/project-open"
} {
    set unixaoldir ""
    if {[info exists ::env(AOLDIR)]} {
	set winaoldir $::env(AOLDIR)
	set unixaoldir [string map {\\ /} ${winaoldir}]
    } else {
	set pageroot [acs_root_dir]
	# Something like c:/project-open/servers/projop
	set pageroot_pieces [split $pageroot "/"]
	set pos [lsearch $pageroot_pieces "servers"]
	if {$pos > 0} {
	    set unixaoldir [join [lrange $pageroot_pieces 0 $pos-1] "/"]
	}
    }
    ns_log Notice "im_exec_windows_basedir: unixaoldir=$unixaoldir"
    return $unixaoldir
}


# --------------------------------------------------------
# OpenACS Version
# --------------------------------------------------------


ad_proc -public im_openacs54_p { } {
    Is OpenACS beyond 5.1.5?
    The higher versions support header files.
} { 
    set o_ver_sql "select substring(max(version_name),1,3) from apm_package_versions where package_key = 'acs-kernel'"
    set oacs_version [util_memoize [list db_string o_ver $o_ver_sql]]
    return [expr 1 > [string compare "5.4" $oacs_version]]
}


# ------------------------------------------------------------------
# System Functions
# ------------------------------------------------------------------


ad_proc -public im_root_dir { } {
    Returns a Linux/CygWin path to the main
    directory of the current server.
    Sample output:
    /web/projop or
    /cygdrive/c/project-open/servers/projop
} {
    set result [string tolower [acs_root_dir]]

    # check for "c:/..."
    if {[regexp {^([a-z]):/(.*)} $result match drive_letter path]} {
	return "/cygdrive/$drive_letter/$path"
    }
    return $result
}


ad_proc -public im_bash_command { } {
    Returns the path to the BASH command shell, depending on the
    operating system (Windows, Linux or Solaris).
    The resulting bash command can be used with the "-c" option 
    to execute arbitrary bash commands.
} {

    # Find out if platform is "unix" or "windows"
    global tcl_platform
    set platform [lindex $tcl_platform(platform) 0]

    switch $platform {
	unix
	{
	    # BASH in Unix can always be found in /bin/...
	    return "/bin/bash"
	}
	windows {
	    # "windows" means running under CygWin
	    set acs_root_dir [acs_root_dir]
	    set acs_root_dir_list [split $acs_root_dir "/"]
	    set acs_install_dir_list [lrange $acs_root_dir_list 0 end-1]
	    set acs_install_dir [join $acs_install_dir_list "/"]

	    set result "$acs_install_dir/bin/bash"
	    return $result
	}
	
	default {
	    ad_return_complaint 1 "Internal Error:<br>
            Unknown platform '$platform' found.<br>
            Expected 'windows' or 'unix'."
	}    
    }
}


# ---------------------------------------------------------------
# System MAC Address
# ---------------------------------------------------------------

ad_proc im_system_ip_mac_address { } {
    Retreives the MAC address of the first IP interface
    on both Linux and Windows machines
} {
    global tcl_platform
    set platform $tcl_platform(platform)

    ns_log Notice "im_system_ip_mac_address: platform=$platform"
    switch $platform {
	"windows" {return [im_system_ip_mac_address_windows] }
	"unix" - "linux" {return [im_system_ip_mac_address_linux] }
    }
    return [im_system_ip_mac_address_linux]
}


ad_proc im_system_ip_mac_address_linux { } {
    Retreives the MAC address of the first IP interface on Linux
} {
    # Linux and Solaris - extract the MAC address from ifconfig
    set ip_address ""
    set mac_address ""

    set mac_lines ""
    catch {set mac_lines [im_exec ifconfig]} err_msg

    # Extract the MAC address from the mac_lines
    foreach mac_line [split $mac_lines "\n"] {
	set mac_line [string tolower $mac_line]

	# Filter out MAC address
	if {"" eq $mac_address && ([regexp {hwaddr} $mac_line] || [regexp {ether} $mac_line]) } {
	    regsub -all {:} $mac_line {-} mac_line
	    regexp {([0-9a-z][0-9a-z]\-[0-9a-z][0-9a-z]\-[0-9a-z][0-9a-z]\-[0-9a-z][0-9a-z]\-[0-9a-z][0-9a-z]\-[0-9a-z][0-9a-z])} $mac_line match mac_address
	}
	
	# Filter out IPv4 address
	if {"" eq $ip_address && [regexp {inet\ +([0-9\.]+)} $mac_line match ip]} {
	    set ip_address $ip
	}
    }
    if {"" eq $ip_address} { set ip_address "127.0.0.1" }
    return [list $ip_address $mac_address]
}



ad_proc im_system_ip_mac_address_windows { } {
    Retreives the MAC address of the first IP interface on Windows
} {
    # Extract the MAC address from ifconfig
    set ip_address ""
    set mac_address ""
    set mac_lines ""
    catch {
	set mac_lines [im_exec ipconfig "/all"]
    } err_msg

    foreach mac_line [split $mac_lines "\n"] {
	set mac_line [string tolower $mac_line]

	# Filter out IPv4 address
	if {"" eq $ip_address && [regexp {ipv4.+([0-9\.]+)} $mac_line match ip]} {
	    set ip_address $ip
	}

	# DUID line - similar to MAC, but not suitable
	if {[regexp {duid.+[0-9a-z][0-9a-z]\-[0-9a-z][0-9a-z]\-[0-9a-z][0-9a-z]\-[0-9a-z][0-9a-z]\-[0-9a-z][0-9a-z]\-[0-9a-z][0-9a-z]\-[0-9a-z][0-9a-z]\-[0-9a-z][0-9a-z]\-[0-9a-z][0-9a-z]\-[0-9a-z][0-9a-z]\-[0-9a-z][0-9a-z]\-[0-9a-z][0-9a-z]\-[0-9a-z][0-9a-z]\-[0-9a-z][0-9a-z]} $mac_line]} { continue }

	regexp {([0-9a-z][0-9a-z]\-[0-9a-z][0-9a-z]\-[0-9a-z][0-9a-z]\-[0-9a-z][0-9a-z]\-[0-9a-z][0-9a-z]\-[0-9a-z][0-9a-z])} $mac_line match mac_address
	if {"" ne $mac_address} { break }
    }

    if {"" eq $ip_address} { set ip_address "127.0.0.1" }
    return [list $ip_address $mac_address]
}



# ---------------------------------------------------------------
# System Identification
# ---------------------------------------------------------------

ad_proc im_system_id { 
    -clear:boolean
} {
    Retreives and/or creates a unique identification.
    We need the SID to check if a system has been registered
    for ASUS and other update services.
} {
    if {$clear_p} {
 	db_dml create_sid "
                update users set salt = null
                where user_id = 0;
        "
    }

    # Extract the SystemID from the "hash" field of the 
    # "guest" user. This field is never set in OpenACS
    # installations, and will never be used because
    # "guest" can't login.
    set sid_hash [db_string sid "select salt from users where user_id = 0" -default ""]

    # Create a new sid_hash if this is the first time 
    # this function is called
    if {"" == $sid_hash} {
	set sid_hash [sec_random_token]
	db_dml create_sid "
		update users set salt = :sid_hash
		where user_id = 0;
        "
    }

    # extract the last 4 groups of 4 digits
    regexp {.*(....)(....)(....)(....)$} $sid_hash match s0 s1 s2 s3

    # Calculate a sha1-hash of the sid_hash to check for 
    # badly entered characters
    set control_digits [string range [ns_sha1 "$s0$s1$s2$s3"] 36 39]
    
    # The full SID consists of 4 groups plus the control digits
    set sid "$s0-$s1-$s2-$s3-$control_digits"

    return $sid
}



ad_proc im_system_id_is_valid { sid } {
    Checks a manually entered SID for typos
} {
    if {![regexp {^(....)\-(....)\-(....)\-(....)\-(....)$} $sid match s0 s1 s2 s3 control]} { return 0 }
    set control_digits [string range [ns_sha1 "$s0$s1$s2$s3"] 36 39]
    if {$control == $control_digits} { return 1 } else { return 0 }
}



# ---------------------------------------------------------------
# Which Database are we running on?
# ---------------------------------------------------------------

ad_proc im_database_version { } {
    Returns the version ID of the PostgreSQL database.
    Returns an empty string in case of an error.
    Example: "8.2.11"
} {
    set postgres_version ""
    catch {
	# Get the _server_ version of PG
	set postgres_version [db_string server_version "SHOW server_version"]
	if {[regexp {([0-9]+\.[0-9]+\.[0-9]+)} $postgres_version match v]} { set postgres_version $v}
    } err_msg

    # There is an issue with psql returning an error message in some
    # Strange Windows configurations. This clause will deal with this:
    if {"" == $postgres_version}  {
        if {[regexp {([0-9]+\.[0-9]+\.[0-9]+)} $err_msg match v]} { set postgres_version $v}
    }

    return $postgres_version
}


# ---------------------------------------------------------------
# Get a hardware ID (MAC address of eth0
# ---------------------------------------------------------------

ad_proc im_hardware_id { } {
    Returns a unique ID for the hardware. We use a MAC address.
    Returns an empty string if the MAC wasn't found.
    Example: "00:23:54:DF:77:D3"
} {
    set mac_address ""
    set mac_line ""
    global tcl_platform
    if { [string match $tcl_platform(platform) "windows"] } {
	
	# Windows - Use Maurizio's code
	catch {
	    set mac_address [string trim [im_exec "w32oacs_get_mac"]]
	} err_msg

    } else {

	# Linux and Solaris - extract the MAC address from ifconfig
	set mac_address ""
	catch {
	    set mac_line [im_exec bash -c "/sbin/ifconfig | grep HWaddr | tail -n1"]
	} err_msg

	# Extract the MAC address from the mac_line
	set mac_line [string tolower $mac_line]
	regsub -all {:} $mac_line {-} mac_line
	regexp {([0-9a-z][0-9a-z]\-[0-9a-z][0-9a-z]\-[0-9a-z][0-9a-z]\-[0-9a-z][0-9a-z]\-[0-9a-z][0-9a-z]\-[0-9a-z][0-9a-z])} $mac_line match mac_address
	
    }

    # return the SystemID in case of an error.
    if {"" == $mac_address} { return [im_system_id] }


    # The MAC address may be considered critical information.
    # So let's calculate a hash value of the MAC to protect its value:
    set mac_hash [ns_sha1 $mac_address]

    # extract the last 4 groups of 4 digits
    regexp {.*(....)(....)(....)(....)$} $mac_hash match s0 s1 s2 s3

    # Calculate a sha1-hash of the sid_hash to check for
    # badly entered characters
    set control_digits [string range [ns_sha1 "$s0$s1$s2$s3"] 36 39]

    # The full HID consists of 4 groups plus the control digits
    set hid "$s0-$s1-$s2-$s3-$control_digits"

    return $hid
}



# ---------------------------------------------------------------
# Which version of ]po[ are we running here?
# ---------------------------------------------------------------

ad_proc im_core_version { } {
    Returns the version number of the "intranet-core" package.
    Example return value: "3.4.0.5.4"
} {
    set core_package_version_sql "
		select	version_name
		from	apm_package_versions
		where	package_key = 'intranet-core' and
			enabled_p = 't'
    "
    set core_version [db_string core_version $core_package_version_sql -default ""]
    return $core_version
}


ad_proc im_linux_distro { } {
    Tries to guess the name of the linux distro if running on Linux.
    Distro is one of {unknown, suse, united, debian, ubuntu, centos, rhel}
} {
    # Determine the Linux distribution and version that is being run.
    # ToDo: No check for Ubuntu yet
    
    set distro "unknown"
    if {[file exists /etc/SuSE-release]} { set distro suse }
    if {[file exists /etc/UnitedLinux-release]} { set distro united }
    if {[file exists /etc/debian_version]} { set distro debian }

    # Distinguish between different Red Hat versions
    set is_rh_p [file exists /etc/redhat-release]
    if {$is_rh_p} {
	set rhel_string ""
	catch { set rhel_string [string tolower [::fileutil::cat /etc/redhat-release]] }
	if {[regexp {^centos} $rhel_string match]} { set distro centos}
	if {[regexp {^red hat linux} $rhel_string match]} { set distro rh }
	if {[regexp {^red hat enterprise} $rhel_string match]} { set distro rhel }
	if {[regexp {^cern} $rhel_string match]} { set distro rhel }
	if {[regexp {^scientific} $rhel_string match]} { set distro rhel }
    }

    # Check for Debian or Ubuntu
    if {"unknown" == $distro} {
	set issue ""
	catch { append issue [::fileutil::cat /etc/issue] }
	catch { append issue [::fileutil::cat /etc/issue.net] }
	set issue [string tolower $issue]

	if {[regexp {ubuntu} $issue]} { set distro ubuntu }
	if {[regexp {debian} $issue]} { set distro debian }
    }

    return $distro
}

ad_proc im_linux_vmware_p { } {
    Returns 1 if the current system is the default CentOS Linux VMware.
} {
    set modules ""
    catch { set modules [im_exec lsmod] }

    if {[lsearch $modules "vmnet"] > -1} { return 1 }
    if {[lsearch $modules "vmw_balloon"] > -1} { return 1 }
    return 0
}

