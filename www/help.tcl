# /packages/intranet-core/www/help.tcl
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
    P/O Main Help Page.

    This page should display context sensitive help in the
    future when called from a page, from a component or
    from an objects field "help" icon.

    @author frank.bergmann@project-open.com
} {

}

# ---------------------------------------------------------------
# Security & Defaults
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

set page_title "[_ intranet-core.HelpPage]"
set context_bar [im_context_bar $page_title]

set bgcolor(0) " class=rowodd"
set bgcolor(1) " class=roweven"


# ---------------------------------------------------------------
# Context sensitive help
# ---------------------------------------------------------------

set context_help "<i>[lang::message::lookup "" intranet-core.No_context_help_available "No context help available"]</i>"


set general_help "
<ul>
  <li><A href=http://www.project-open.org/doc/>
	<span class=brandsec>&#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&#91;</span>
	Documentation
  </a>
</ul>
"

set developer_help "
<ul>
  <li><A href=http://www.project-open.org/en/faq_developers>
	<span class=brandsec>&#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&#91;</span>
      Documentation</a>
</ul>
"


db_release_unused_handles
