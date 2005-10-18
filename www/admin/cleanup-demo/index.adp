<master src="../master">
<property name="title">@page_title;noquote@</property>
<property name="admin_navbar_label">admin_home</property>

<!-- left - right - bottom  design -->

<table cellpadding=0 cellspacing=0 border=0 width=100%>
<tr>
  <td valign=top>

    <H2><font color=red>@page_title;noquote@</font></H2>
    Intentionally destroy your system!


    <ul>

      <li>
        <A href=../backup/pg_dump>#intranet-core.PostgreSQL_Backup#</A><br>
        #intranet-core.PostgreSQL_Backup_blurb#
        <br>&nbsp;<br>

      <li>
	<A href="cleanup-demo-data">Cleanup all demo data in the system.</A><br>
          This commands deletes all the user data data (projects, companies,
	  forum discussions, invoices, timesheet, ) in the system and leaves
          the database completely empty, except for the basic system configuration
	  (permissions, categories, parametes, ...) and user
          accounts (delete them selectively below). <br>
          This command is useful in order to start production
          operations from a demo system, but should never
          be used otherwise.<br>&nbsp;<br>
      <li>
	<A href="cleanup-users">Cleanup Remaining Users</A><br>
	Cleanup up demo data above will leave a certain number of
	users still in the system. Use this page to delete them.
    </ul>

  </td>
  <td valign=top>
    <%= [im_component_bay right] %>
  </td>
</tr>
</table><br>

<table cellpadding=0 cellspacing=0 border=0>
<tr><td>
  <%= [im_component_bay bottom] %>
</td></tr>
</table>


