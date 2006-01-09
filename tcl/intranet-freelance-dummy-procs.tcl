# /packages/intranet-core/tcl/intranet-freelance-dummy-procs.tcl
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
    Dummy component as a placeholder for the freelance
    component in the "Add Members" page.

    @author frank.bergmann@project-open.com
}

# ---------------------------------------------------------------
# Freelance Member Select Component
# ---------------------------------------------------------------

# this proc is only used without quality module

ad_proc im_freelance_member_select_dummy_component { object_id return_url } {
    Placeholder for the im_freelance_member_select_component
    in the add-members.tcl page
} {
    set select_freelance "
<table cellpadding=0 cellspacing=2 border=0>
<tr>
<td class=rowtitle align=middle colspan=5>Freelance</td>
<tr>
  <td class=rowtitle>Freelance</td>
  <td class=rowtitle>Source Language</td>
  <td class=rowtitle>Target Language</td>
  <td class=rowtitle>Subject Area</td>
  <td class=rowtitle>Select</td>
</tr>
<tr><td colspan=5>asdf</td></tr>
</table>
\n"


    return $select_freelance
}

