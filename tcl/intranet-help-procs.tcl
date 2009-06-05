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
	
      <h2>[lang::message::lookup "" intranet-core.Welcome_to_po "
		Welcome to %projop%
      "]</h2>[lang::message::lookup "" intranet-core.Sample_system_blurb "
		We have set up this 'Tigerpond' sample company on this server 
		in order to show you what your future $po could look like.
      "]<p>&nbsp;</p>

      <h2>[lang::message::lookup "" intranet-core.Starting_to_use_the_system_blurb "
		Starting to use %po%
      "]</h2>[lang::message::lookup "" intranet-core.Welcome_to_po_blurb "
		You can use 'Admin' -&gt; 'Cleanup Demo Data' to remove all
		demo data from this server and to start using this server in production.
      "]<p>&nbsp;</p>

      <h2>[lang::message::lookup "" intranet-core.Online_resources_header "Online Resources"]</h2>
      <ul>
      <li>
        <A href=\"http://www.project-open.com/\"><b>[lang::message::lookup "" intranet-core.PO_com_web_site "
		%po% '.com' Web site
	"]</b></a>:<br>
	[lang::message::lookup "" intranet-core.PO_com_web_site_blurb "
		Provides you with an overview of %po%.
	"]<br>&nbsp;<br>
	</li>
	<li>
	  <A href=\"http://www.project-open.org/documentation/\"><B>[lang::message::lookup "" intranet-core.PO_Documentation_Wiki "
		%po% Documentation Wiki
	  "]</b></a>:<br>[lang::message::lookup "" intranet-core.PO_Documentation_Wiki_Blurb "
		Contains reference information on %po% processes, packages, objects etc.
	  "]<br>&nbsp;<br>
	</li>
	<li>
	  <A href=\"http://sourceforge.net/forum/forum.php?forum_id=295937\"><b>[lang::message::lookup "" intranet-core.SourceForge_Forum "
		SourceForge Forum
	  "]</b></a>:<br>[lang::message::lookup "" intranet-core.SourceForge_Forum_Blurb "
		You can use the forums to communicate with other %po% users.
	  "]<br>&nbsp;<br>
	</li>
	<li>
	  <A href=\"http://www.project-open.com/en/services/\"><b>[lang::message::lookup "" intranet-core.PO_Professional_Services "
		Professional Services
	  "]</b></a>:<br>[lang::message::lookup "" intranet-core.PO_Professional_Services "
		Involving us in your %po% rollout will save you a lot of time
		with installation and configuration."]
	  <br>&nbsp;<br>
	</li>
	<li>
	  <A href=\"http://www.project-open.com/en/services/project-open-support.html\"><b>[lang::message::lookup "" intranet-core.PO_Support_Contracts "
		Support Contracts
	  "]</b></a>:<br>[lang::message::lookup "" intranet-core.PO_Support_Contracts_Blurb "
		We can also provide you with a support contract to keep your system safe and running.
	  "]
	</li>
	</ul>
	</p>
	</td></tr>
	</table>    
	<br>
    "
}
