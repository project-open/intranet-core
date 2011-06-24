<master src="../master">
<property name="title">@page_title;noquote@</property>
<property name="admin_navbar_label">admin_home</property>

<!-- left - right - bottom  design -->

<table cellpadding=0 cellspacing=0 border=0>
<tr>
  <td valign=top>

    <H2><font color=red>@page_title;noquote@</font></H2>
    <br>
    <table style='background-color:#FFFFCC' border="0"><tr><td valign="top">
    <h3><strong><%= [lang::message::lookup "" intranet-core.DelDemo_Prepare_for_prod "Prepare your system for production use"] %></strong></h3>
    <%= [lang::message::lookup "" intranet-core.DelDemo_Please_follow_the_steps "
    Please follow the step below to remove all application data
    from your system including projects, companies, users,
    financial information, forum discussion etc."] %>
    <br>&nbsp;
    </p>
    <p>
    <%= [lang::message::lookup "" intranet-core.DelDemo_However_this_procedure "
    However, this procedure will not affect configuration
    data including menus, portlet components, categories
    etc."] %>
    <br>&nbsp;
    </p>

    <ol>

      <li>
        <A href=../backup/pg_dump>#intranet-core.PostgreSQL_Backup#</A><br>
	<%= [lang::message::lookup "" intranet-core.DelDemo_Please_backup "
	Please backup your current database contents before continuing
	with any of the following commands."] %>
        <br>&nbsp;<br>
      <li>
        <A href="cleanup-demo-data"><%= [lang::message::lookup "" intranet-core.DelDemo_Nuke_all_demo_data "Nuke all demo data in the system"] %></A><br>
	<%= [lang::message::lookup "" intranet-core.DelDemo_This_command_nukes "
          This commands nukes (permanently deletes) all data in the system
	  such as projects, companies, forum discussions, invoices, timesheet, etc.
	  It leaves the database completely empty, except for the basic 
	  system configuration (permissions, categories, parametes, ...) and user
          accounts (delete them selectively below). <br>
          This command is useful in order to start production
          operations from a demo system, but should never
          be used otherwise."] %>
	  <br>&nbsp;<br>
     </ol>
     </td></tr></table>
     <br>
     <h3><%= [lang::message::lookup "" intranet-core.DelDemo_Delete_Individual_objects "Delete Individual Objects"] %></h3>
     
     <p> <b>In case you have just installed ]po[ and intend to start production, please follow the steps as decribed above.</b> The links below allow you to nuke single data when your system is in production.<br>
	 In some cases you might not be able to delete an object permanently due to existing constrains on a database level. If this happens, please contact your System Administrator.</p><br>
     <ul>
      <li>
	<A href="cleanup-users"><%= [lang::message::lookup "" intranet-core.DelDemoNuke_Demo_Users2 "Nuke Demo Users"] %></A><br>
	<%= [lang::message::lookup "" intranet-core.DelDemo_Nuke_Demo_Users2_Msg "
          This commands allows you to selectively 'nuke' (permanently delete) 
	  users from the system, including all of their associated data such
	  as portraits, tasks, forum discussions, timesheet, ..."] %>
	  <br>&nbsp;<br>

      <li>
	<A href="cleanup-projects"><%= [lang::message::lookup "" intranet-core.DelDemo_Nuke_Demo_Projects "Nuke Demo Projects"] %></A><br>
	<%= [lang::message::lookup "" intranet-core.DelDemo_Nuke_Demo_Projects_Msg "
          This commands allows you to selectively 'nuke' (permanently delete) 
	  projects from the system, including all of their associated data such
	  as tasks, forum discussions, invoices, timesheet, ..."] %>
	  <br>&nbsp;<br>

      <li>
	<A href="cleanup-companies"><%= [lang::message::lookup "" intranet-core.DelDemo_Nuke_Demo_Companies "Nuke Demo Companies"] %></A><br>
	<%= [lang::message::lookup "" intranet-core.DelDemo_Nuke_Demo_Companies_Msg "
          This commands allows you to selectively 'nuke' (permanently delete) 
	  companies from the system, including all of their associated data such
	  as offices, projects, forum discussions...)."] %>
	  <br>&nbsp;<br>

      <li>
	<A href="cleanup-offices"><%= [lang::message::lookup "" intranet-core.DelDemo_Nuke_Demo_Offices "Nuke Demo Offices"] %></A><br>
	<%= [lang::message::lookup "" intranet-core.DelDemo_Nuke_Demo_Offices_Msg "
          This commands allows you to selectively 'nuke' (permanently delete) 
	  offices from the system, including all of their associated data such)."] %>
	  <br>&nbsp;<br>
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


