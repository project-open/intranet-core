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
  <A href=\"http://www.project-open.com/product/modules/\"><B>
    Project/Open Feature Overview</b></a>:<br>
  Our web page gives you an overview over the
  different Project/Open modules
  and briefly explains their functionality.
</li>
<li>
  <A href=\"http://sourceforge.net/project/showfiles.php?group_id=86419&package_id=89751&release_id=281910\"><b>
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


<h2>Configuring Your System</h2>

<p>
In order to configure your new system, please follow the
instructions in the
<a href=\"http://prdownloads.sourceforge.net/project-open/PO-Configuration-Guide.050113.pdf?download\">Project/Open Configuration Guide</a>.
Please <a href=\"http://www.project-open.com/contact/\">contact us</a>
for more information.
</p>

<p>
After the basic configuration you can start setting up
your corporate environment. We recommend that you start
in the following order:

<ul>
<li>Set up some employees, customers and freelancers
    in the \"Users\" menu, using sample values from your
    corporate environment.
<li>Set up your own company in the \"Companies\" menu.
    Please note that your own company needs to have
    Company Short Name = \"internal\" (lower case letters!) and
    Company Type = \"Internal\", in order to be identified
    as such.
<li>Set up some customers and providers in the
    \"Companies\" menu and use \"Add member\" link to add some
    of the system users that you have set up above.
<li>Set up some projects in the \"Projects\" menu, using
    sample values from your corporate environment.
<li>Start reading the users guides from the download zone
    above for detailed configuration of the other modules
    or <a href=\"http://www.project-open.com/contact/\">contact us</a>
    for professional training.
</ul>
</p>


</td></tr>
</table>    
"
}


