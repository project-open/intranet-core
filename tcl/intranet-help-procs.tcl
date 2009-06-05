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
    set title [lang::message::lookup "" intranet-core.ProjectOpen_News "&\\#93;po&\\#91; News"]
    set no_iframes_l10n [lang::message::lookup "" intranet-core.Your_browser_cant_display_iframes "Your browser can't display IFrames."]

    set url "http://projop.dnsalias.com/intranet-rss-reader/index?format=iframe300&max_news_per_feed=3"
    set url [parameter::get_from_package_key -package_key "intranet-core" -parameter HomeNewsComponentUrl -default $url]

    set iframe "
      <iframe src=\"$url\" width=\"100%\" height=\"300\" name=\"$title\" frameborder=0>
        <p>$no_iframes_l10n</p>
      </iframe>
    "
    return $iframe
    # return [im_table_with_title $title $iframe]
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

<h1>[lang::message::lookup "" intranet-core.Welcome_to_po "Welcome to %projop%"]</h1>

[lang::message::lookup "" intranet-core.Sample_system_blurb "
We have set up a sample system for you in order to show you how
a typical company could look like. 
"]

<h2>[lang::message::lookup "" intranet-core.Starting_to_use_the_system_blurb "Starting to use %po%"]</h2>

[lang::message::lookup "" intranet-core.Welcome_to_po_blurb "
You can use 'Admin' -&gt; 'Cleanup Demo Data' to remove the
demo data from this server and start using this server in production
if you are a small organization.<p>
"]

<!--
<h2>[lang::message::lookup "" intranet-core.Online_resources_header "Online Resources"]</h2>

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
</p>-->
</td></tr>
</table>    
<br>
"
}
