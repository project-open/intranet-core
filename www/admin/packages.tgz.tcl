# /packages/intranet-core/www/admin/packages.tgz.tcl
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

ad_page_contract {
    Return a gziped TAR of the ~/packages/ directory
    @author frank.bergmann@project-open.com
} {
    
}

# ---------------------------------------------------------------
# Security & Defaults
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set page_title "packages.tgz"

set tmp_file "[ns_tmpnam].tgz"
set server_path [acs_root_dir]

if { [catch {
    exec bash -c "cd $server_path; tar czf $tmp_file packages"
} err_msg] } {
    ad_return_complaint 1 "<b>Error creating TGZ file</b>:<pre>$err_msg</pre>"
    ad_script_abort
}

set file_readable 0
if { [catch {
    set file_readable [file readable $tmp_file]
} err_msg] } {
    ad_return_complaint 1 "<b>Error creating tmp_file=$tmp_file</b><pre>$err_msg</pre>"
    ad_script_abort
}

if $file_readable {
    rp_serve_concrete_file $tmp_file
    ad_script_abort
}

