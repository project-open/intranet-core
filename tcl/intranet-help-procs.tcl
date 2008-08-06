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
a typical company could look like. 

Currently we are preparing some tutorial flash demos. Here's a first 
sample, expect more to come soon. 


Please follow the links to explore the (freely invented) sample contents.

<h2>Starting to use $po</h2>

<p>
You can use 'Admin' -&gt; 'Cleanup Demo Data' to remove the
demo data from this server and start using this server in production
if you are a small organization.<p>

For a complete rollout overview please see our 
<a href=\"http://project-open.sourceforge.net/whitepapers/Project-Open-Rollout-Plan.ppt\"
>Rollout Plan</a>. Please
<A href=\"http://www.project-open.com/en/company/project-open-contact.html\">contract us</a>
for a quote on professional services. We have helped more then 100
organizations to get the most out of $projop.


<h2>Online Resources</h2>

<ul>
<li>
  <a href=\"http://sourceforge.net/projects/project-open/\"><b>SourceForge Open-Source Community</b></a>:<br>
  This is the place where you can interact with the developers of
  $projop, ask for help etc.
  <br>&nbsp;<br>
</li>

<li>
  <A href=\"http://www.project-open.org/doc/\"><b>
  $projop Documentation and User Guides</b></a>:<br>
   Please see the list of all available documentation.
  <br>&nbsp;<br>
</li>

<li>
  <A href=\"http://www.project-open.org/product/modules/\"><B>
  $projop Feature Overview</b></a>:<br>
  Our web page gives you an overview over the different
  $projop modules and briefly explains their functionality.
  <br>&nbsp;<br>
</li>

<li>
  <A href=\"http://www.project-open.com/en/services/project_open_support.html\"><b>
    Professional Support</b></a>:<br>
    Please consider to contract professional support. 
    $projop offers three different support levels for companies of all sizes.
  <br>&nbsp;<br>
</li>
</ul>

</p>
</td></tr>
</table>    
<br>
"
}
