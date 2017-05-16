<master src="master">
<property name="doc(title)">@page_title;literal@</property>
<property name="admin_navbar_label">admin_home</property>

<!-- left - right - bottom  design -->

<table cellpadding="0" cellspacing="0" border="0" width="100%">
<tr><td colspan=2><%= [im_component_bay top] %></td></tr>
<tr>
  <td valign="top">
    <%= [im_table_with_title "Administration" $menu_html] %>


<!--
    <ul>
      <li>
	<A href="/intranet/admin/auto_login">Auto-Login Backup Configuration</a><br>
	Returns the address to download a backup remotely.
      <li>
	<A href="/cms/"">Content Management Home</a><br>
	This module is used as part of the Wiki and CRM packages.

    </ul>
-->

    <%= [im_component_bay left] %>




<br>
    <%= [im_table_with_title "<font color=red>#intranet-core.Dangerous#</font>" "
    <ul>
	<li>
	  <a href='/intranet/admin/cleanup-demo/'>Cleanup Demo Data</a><br>
	  This menu allows you to delete all the data in the system and leaves
	  the database completely empty, except for master data, 
	  permissions and the administrator accounts. <br>
	  This command is useful in order to start production
	  operations from a demo system, but should never
	  be used otherwise.<br>&nbsp;<br>

	<li>
	  <a href='/intranet/admin/windows-to-linux'>Convert parameters from Windows to Linux</a><br>
          Use this if you have imported a backup dump from a Windows system
	  to this Linux system.
	  This script simplemented sets the operating specific parameters
	  such as pathces and commands. You could do this manually, but
          it's more comfortable this way.<br>
          The command assumes that Windows installations are found in X:/ProjectOpen/projop/,
	  while Linux installations are in /web/projop/.
	  <br>&nbsp;<br>

	<li>
	  <a href='/intranet/admin/linux-to-windows'>Convert parameters from Linux to Windows</a><br>
          The reverse of the command above. 
	  <br>&nbsp;<br>

	<li>
	  <a href='/intranet/anonymize'>#intranet-core.lt_Anonymize_this_server#</a>
    </ul>
    "] %>


  </td>

  <td valign="top" width="400px">
    <%= [im_component_bay right] %>
  </td>
</tr>
</table><br>


<table cellpadding="0" cellspacing="0" border="0">
<tr><td>
<%= [im_component_bay bottom] %>
</td></tr>
</table>


