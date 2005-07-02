# /packages/intranet-core/tcl/intranet-help-procs.tcl
#
# Copyright (C) 2004 Project/Open
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
    Procedures to deal with online help and preconfiguration

    @author frank.bergmann@project-open.com
}


ad_proc -public im_help_home_page_blurb_component { } {
    Creates a HTML table with a blurb for the "home" page.
    This has been made into a component in order to allow
    users to remove it from the home page.
} {
    return "
<table cellpadding=2 cellspacing=2 border=0 width=100%>
<tr><td>

<h1>Welcome to Project/Open</h1>

<h2>Getting Help</h2>

Help is available for you in various ways:

<ul>
<li>
  <A href=\"http://www.project-open.org/product/modules/\"><B>
    Project/Open Feature Overview</b></a>:<br>
  Our web page gives you an overview over the
  different Project/Open modules
  and briefly explains their functionality.
</li>
<li>
  <A href=\"http://sourceforge.net/project/showfiles.php?group_id=86419\"><b>
    Project/Open User Guides</b></a>:<br>
  Please visit the download zone of our
  <a href=\"http://sourceforge.net/projects/project-open/\">developer community</a>.
  Here you will find all relevant guides and manuals in \".pdf\" format.
</li>

<li>
  <A href=\"http://www.project-open.org/doc/\"><b>
    Complete List of Documentation</b></a>:<br>
    Please see the list of all available documentation.
</li>

<li>
  <A href=\"http://sourceforge.net/forum/forum.php?forum_id=295937\"><b>
    Discussion Forums</b></a>:<br>
    You can use the open discussion forums to start communicating
    with the open-source community.
</li>

<li>
  <A href=\"http://www.project-open.com/product/services/support/\"><b>
    Professional Support</b></a>:<br>
    Please consider to contract professional support.
    Project/Open offers three different support levels for
    companies of all sizes.
</li>
</ul>

<h2>Exploring the System</h2>

<p>
We have set up a sample system for you in order to show you how
a typical company could look like. Please follow the links to
explore the (freely invented) sample contents.
</p>


<h2>Using Project/Open in Your Company</h2>

<p>
This sample configuration could already serve you as the base for a
small company's system if you change the data of the existing users, 
customers and providers and replace them with your real data.
</p><p>
However, the security settings and the database of this demo are not 
suitable for production use. For a more suitable configuration please 
consult the system documentation above or 
<A href=\"http://www.project-open.com/contact/\">contact us</a>
in order to plan and execute a more formal implantation project
covering aspects such as training, maintenance, Internet connectivity,
backup and recovery etc. 
</p>
</td></tr>
</table>    
<br>
"
}
