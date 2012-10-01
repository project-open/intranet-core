<master src="master">
<property name="title">@page_title;noquote@</property>
<property name="admin_navbar_label">admin_home</property>

<!-- left - right - bottom  design -->
<br>

<table cellpadding=0 cellspacing=0 border=0 width="100%">
<tr>
  <td valign=top>

    <H2>Documentation</H2>
    <ul>
      <li><A href="http://www.project-open.org/en/" target="_blank">General Documentation</a><br></li>
      <li><A href="http://www.project-open.org/en/page_intranet_admin_index" target="_blank">Context help for this page <%= [im_gif help] %></a><br></li>
    </ul>

<br>

    <H2>Administration</H2>

	@menu_html;noquote@

<!--
    <ul>
      <li>
	<A href="/intranet/admin/auto_login">Auto-Login Backup Configuration</a><br>
	Returns the address to download a backup remotely.
      <li>
	<A href=/cms/">Content Management Home</a><br>
	This module is used as part of the Wiki and CRM packages.

    </ul>
-->

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

	<li>
	  <a href=/intranet/anonymize>#intranet-core.lt_Anonymize_this_server#</a>
    </ul>



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


