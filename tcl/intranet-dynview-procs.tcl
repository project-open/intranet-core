# /packages/intranet-core/tcl/intranet-view-procs.tcl
#
# Copyright (C) 2004 ]project-open[
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
    Library with auxillary routines related to DynViews
    (system views)

    @author frank.bergmann@project-open.com
}


# Frequently used DynView Types
ad_proc -public im_dynview_type_list {} { return 1400 }
ad_proc -public im_dynview_type_view {} { return 1405 }
ad_proc -public im_dynview_type_backup {} { return 1410 }


