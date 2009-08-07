# /packages/intranet-core/tcl/intranet-audit-procs.tcl
#
# Copyright (C) 2007 ]project-open[
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
    Stubs for object auditing.
    Audit is implemented in the package intranet-audit.
    This file only contains "stubs" to the calls in
    intranet-audit.

    @author frank.bergmann@project-open.com
}



# -------------------------------------------------------------------
# 
# -------------------------------------------------------------------

ad_proc -public im_audit  {
    -object_id:required
    {-object_type "" }
} {
    Generic audit for all types of objects.
} {
    catch {
	set err_msg [im_audit_impl -object_id $object_id -object_type $object_type]
    }

    return $err_msg
}


ad_proc -public im_project_audit  {
    { -action update }
    project_id
} {
    Specific audit for projects. This audit keeps track of the cost cache with each
    project, allowing for EVA Earned Value Analysis.
} {
    catch {
	set err_msg [im_project_audit_impl -action update $project_id]
    }

    return $err_msg
}

