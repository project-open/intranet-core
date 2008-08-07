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


ad_proc -public im_home_news_component { } {
    An IFrame to show ]po[ news
} {
    set title [lang::message::lookup "" intranet-core.ProjectOpen_News "&\#93;po&\#91; News"]
    set no_iframes_l10n [lang::message::lookup "" intranet-core.Your_browser_cant_display_iframes "Your browser can't display IFrames."]

    set url "http://projop.dnsalias.com/intranet-rss-reader/index?format=iframe300&max_news_per_feed=3"
    set iframe "
	<iframe src=\"$url\" width=\"100%\" height=\"300\" name=\"$title\" frameborder=0>
	  <p>$no_iframes_l10n</p>
	</iframe>
    "
    return $iframe
    return [im_table_with_title $title $iframe]
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

This server contains the 'Tigerpond' demo company, together with
some typical projects and user profiles. Please follow the links 
to explore these freely invented demo contents.

<h2>Starting to use $po</h2>

<p>
You can use 'Admin' -&gt; 'Cleanup Demo Data' to remove the
demo data from this server and start using this server in production
if you are a small organization.<p>

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
  <B>
  <A href=\"http://project-open.sourceforge.net/whitepapers/Project-Open-Rollout-Plan.ppt\">$projop Rollout Plan (ppt)</a>
  <A href=\"http://project-open.sourceforge.net/whitepapers/Project-Open-Rollout-Plan.pdf\">(pdf)</a></b>:<br>
  This document provides you with an overview on how to rollout
  $projop in a typical service company with 30-300 employees
  (smaller companies don't need such an elaborated procedures).
  Please <a href=\"http://www.project-open.com/en/services/project_open_support.html\">contact us</a>
  for help with your rollout.
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

You can disable this text by clicking on the [im_gif comp_delete] button in the
header of this grey box.

</p>
</td></tr>
</table>    
<br>
"
}
