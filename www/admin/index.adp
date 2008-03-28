<master src="master">
<property name="title">@page_title;noquote@</property>
<property name="admin_navbar_label">admin_home</property>

<!-- left - right - bottom  design -->

<table cellpadding=0 cellspacing=0 border=0 width="100%">
<tr>
  <td valign=top>

    <H2>Documentation</H2>
    <ul>
      <li>
	<A href="/doc/">OpenACS System & Developer Documentation</a><br>
	Complete documentation of the OpenACS underlying platform.
      <li>
	<A href="/intranet-filestorage/" class="nobr"><span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span> Documentation</a><br>
	Documentation of the OpenACS underlying platform.

    </ul>
<br>
<!--
    <H2>Administration</H2>
    <ul>
      <li>
	<A href="profiles/">#intranet-core.Manage_Profiles#</A><br>
	#intranet-core.lt_Configure_site-wide_d#
      <li>
	<A href="menus/">#intranet-core.Manage_Menus#</A><br>
	#intranet-core.lt_Edit_menus_and_change#
      <li>
	<A href="parameters/">#intranet-core.lt_Manage_Global_System_#</A><br>
	#intranet-core.lt_Change_the_system_par#
      <li>
	<A href="components/">#intranet-core.lt_Manage_Component_Layo#</A><br>
	#intranet-core.lt_Change_the_position_o#
      <li>
	<A href="views/"><%= [lang::message::lookup "" intranet-core.Manage_Views "Manage Views"] %></A><br>
	Enable, disable and edit system \"views\" (the columns in lists and reports).
      <li>
	<a href=/intranet-dynfield/>Admin DynField</a><br>
	Add new fields to projects, customers and users. New fields can be
	associated to certain object sub-types. Access can be restricted to
	certain user groups.
      <li>
	<A href=backup>#intranet-core.PostgreSQL_Backup#</A><br>
	#intranet-core.PostgreSQL_Backup_blurb# 
    </ul>
-->

    <H2>Administration</H2>

    <ul>
      <li>
	<A href=flush_cache>#intranet-core.lt_Flush_Permission_Cach#</A><br>
	#intranet-core.lt_Flush_cleanup_the_per#
      <li>
	<A href="/acs-admin/apm/packages-install?update_only_p=1"><%= [lang::message::lookup "" intranet-core.Update_Packages "Update Packages (after an update of the code)"] %></A><br>
	Update the package database.

      <li>
	<A href="/acs-admin/apm/"><%= [lang::message::lookup "" intranet-core.OpenACS_Package_Manager "OpenACS Package Manager"] %></A><br>
	Update, install and uninstall software packages.
      <li>
	<A href="/acs-admin/developer"><%= [lang::message::lookup "" intranet-core.OpenACS_Developer_Tools "OpenACS Developer Tools"] %></A><br>
	Utilities for developers and access to developer documentation and the API-Browser.
      <li>
	<A href="/admin/site-map/"><%= [lang::message::lookup "" intranet-core.OpenACS_Sitemap "OpenACS Sitemap"] %></A><br>
	The Sitemap defines where modules are "mounted" on the server.
	<span class="nobr"><span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span></span> packages are already mounted and shouldn't be moved.
      <li>
	<A href="/intranet/admin/auto_login">Auto-Login Backup Configuration</a><br>
	Returns the address to download a backup remotely.
      <li>
	<A href=/cms/">Content Management Home</a><br>
	This module is used as part of the Wiki and CRM packages.

<!--
      <li>
	<a href=/intranet/projects/import-project-txt>
	  #intranet-core.lt_Import_Projects_from_#
      </a>
-->
    </ul>
    <%= [im_component_bay left] %>

<br>
<h2><font color=red>#intranet-core.Dangerous#</font></h2>
    <ul>
	<li>
	  <a href=/intranet/admin/cleanup-demo/>Cleanup Demo Data</a><br>
	  This menu allows you to delete all the data in the system and leaves
	  the database completely empty, except for master data, 
	  permissions and the administrator accounts. <br>
	  This command is useful in order to start production
	  operations from a demo system, but should never
	  be used otherwise.<br>&nbsp;<br>

	<li>
	  <a href=/intranet/admin/ltc-import/>Import data from LTC-Organiser</a><br>
	  This wizard allows you to import data from the MS-Access 
	  based LTC-Organiser into 
	  <span class="nobr"><span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span></span>.
	  <br>&nbsp;<br>

	<li>
	  <a href=/intranet/admin/windows-to-linux>Convert parameters from Windows to Linux</a><br>
          Use this if you have imported a backup dump from a Windows system
	  to this Linux system.
	  This script simplemented sets the operating specific parameters
	  such as pathces and commands. You could do this manually, but
          it's more comfortable this way.<br>
          The command assumes that Windows installations are found in X:/ProjectOpen/projop/,
	  while Linux installations are in /web/projop/.
	  <br>&nbsp;<br>

	<li>
	  <a href=/intranet/admin/linux-to-windows>Convert parameters from Linux to Windows</a><br>
          The reverse of the command above. 
	  <br>&nbsp;<br>

    </ul>

<!--
	<li>
	  <a href=/intranet/anonymize>#intranet-core.lt_Anonymize_this_server#</a>
-->

  </td>
  <td valign=top width="400px">
    <%= [im_component_bay right] %>
  </td>
</tr>
</table><br>

<table cellpadding=0 cellspacing=0 border=0>
<tr><td>
  <%= [im_component_bay bottom] %>
</td></tr>
</table>


