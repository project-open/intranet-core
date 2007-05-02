# /packages/intranet-core/tcl/intranet-help-procs.tcl
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
    Procedures to deal with online help and preconfiguration

    @author frank.bergmann@project-open.com
}


ad_proc -public im_help_home_page_blurb_component { } {
    Creates a HTML table with a blurb for the "home" page.
    This has been made into a component in order to allow
    users to remove it from the home page.
} {
    set projop "<nobr><span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span></nobr>"
    set po "<nobr><span class=brandsec>&\#93;</span><span class=brandfirst>po</span><span class=brandsec>&\#91;</span></nobr>"

    return "
<table cellpadding=2 cellspacing=2 border=0 width=100%>
<tr><td>

<h1>Welcome to $projop</h1>

We have set up a sample system for you in order to show you how
a typical company could look like. Please follow the links to
explore the (freely invented) sample contents.


<h2>Starting to use $po</h2>

<p>
You can use 'Admin' -&gt; 'Cleanup Demo Data' to remove the
demo data from this server and start using this server in production
if you are a small organization.<p>

For a complete rollout overview please see our 
<a href=\"http://www.project-open.com/whitepapers/Project-Open-Rollout-Plan.ppt\"
>Rollout Plan</a>. Please
<A href=\"http://www.project-open.com/contact/\">contract us</a>
for a quote on professional services. We have helped more then 100
organizations to get the most out of $po.


<h2>Online Resources</h2>

<ul>
<li>
  <A href=\"http://www.project-open.org/product/modules/\"><B>
    &\#93;project-open&\#91; Feature Overview</b></a>:<br>
  Our web page gives you an overview over the different
  $po modules and briefly explains their functionality.
</li>
<li>
  <A href=\"http://www.project-open.org/doc/\"><b>
  $po User Guides</b></a>:<br>
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
    $po offers three different support levels for companies of all sizes.
</li>
</ul>

</p>
</td></tr>
</table>    
<br>
"
}
