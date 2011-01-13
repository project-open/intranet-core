# /package/intranet-core/projects/upload-projects.tcl
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

ad_page_contract {
    Serve the user a form to upload a new file or URL

    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date July 2003
} {
    return_url:notnull
}

set user_id [ad_maybe_redirect_for_registration]
set page_title "Upload Projects CSV"

set context_bar [im_context_bar [list "/intranet/projects/" "Projects"] "Upload CSV"]


set po "<span class=brandsec>&\#93;</span><span class=brandfirst>po</span><span class=brandsec>&\#91;</span>"
