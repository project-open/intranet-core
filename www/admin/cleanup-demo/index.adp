<master src="../master">
<property name="title">@page_title;noquote@</property>
<property name="admin_navbar_label">admin_home</property>

<!-- left - right - bottom  design -->

<table cellpadding=0 cellspacing=0 border=0>
<tr>
  <td valign=top>

    <H2><font color=red>@page_title;noquote@</font></H2>
    <p>
    <h5>Intentionally destroy your system!</h5>
    </p>
    Please follow the step below to entirely cleanup your system.
    The order of the steps is important, because there are many
    dependencies between objects. Objects (for example: a user) 
    can only be deleted if all 'referencing' objects have been
    deleted (for example: projects, forum items, timesheet hours,...
    created by this user).

    <ol>

      <li>
        <A href=../backup/pg_dump>#intranet-core.PostgreSQL_Backup#</A><br>
	Please backup your current database contents before continuing
	with any of the following commands.
        <br>&nbsp;<br>

      <li>
        <A href="cleanup-demo-data">Nuke all demo data in the system.</A><br>
          This commands nukes (permanently deletes) all data in the system
	  such as projects, companies, forum discussions, invoices, timesheet, etc.
	  It leaves the database completely empty, except for the basic 
	  system configuration (permissions, categories, parametes, ...) and user
          accounts (delete them selectively below). <br>
          This command is useful in order to start production
          operations from a demo system, but should never
          be used otherwise.<br>&nbsp;<br>

      <li>
	<A href="cleanup-users">Nuke Demo Users</A><br>
	  Remove any remaining demo users. <br>
          You can't delete System Administrator
          users (so that you can't "lock yourself out" of the system...). 
          In order to delete Admins please remove them from the "P/O Admins" groups
          one-by-one in their users's page.
     </ol>

     <h5>Delete Individual Objects</h5>

     <ul>

      <li>
	<A href="cleanup-users">Nuke Demo Users</A><br>
          This commands allows you to selectively "nuke" (permanently delete) 
	  users from the system, including all of their associated data such
	  as portraits, tasks, forum discussions, timesheet, ...<br>&nbsp;<br>

      <li>
	<A href="cleanup-projects">Nuke Demo Projects</A><br>
          This commands allows you to selectively "nuke" (permanently delete) 
	  projects from the system, including all of their associated data such
	  as tasks, forum discussions, invoices, timesheet, ...<br>&nbsp;<br>

      <li>
	<A href="cleanup-companies">Nuke Demo Companies</A><br>
          This commands allows you to selectively "nuke" (permanently delete) 
	  companies from the system, including all of their associated data such
	  as offices, projects, forum discussions...).<br>&nbsp;<br>
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


