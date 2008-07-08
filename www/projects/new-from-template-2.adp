<master src="../master">
<property name="title">@page_title@</property>
<property name="main_navbar_label">projects</property>

<form action=clone-2.tcl method=POST>
<%= [export_form_vars return_url parent_project_id company_id clone_postfix] %>

  <table border=0>
    <tr> 
      <td colspan=2 class=rowtitle>
        #intranet-core.Project_Base_Data#
      </td>
    </tr>
    <tr> 
      <td>#intranet-core.Project_Name#</td>
      <td> 
	<input type=text size=40 name=project_name value="@project_name@">
	<%= [im_gif help "Please enter any suitable name for the project. The name must be unique."] %>
      </td>
    </tr>
    <tr> 
      <td>#intranet-core.Project_# &nbsp;</td>
      <td> 
	<input type=text size="@project_nr_field_size@" name=project_nr value="@project_nr@" maxlength="@project_nr_field_size@" >
	<%= [im_gif help "A project number is composed by 4 digits for the year plus 4 digits for current identification"] %> &nbsp; 
      </td>
    </tr>

    <tr> 
      <td><%= [lang::message::lookup "" intranet-core.CloneProjectCostsP "Clone Project Costs?"] %> &nbsp;</td>
      <td> 
	<input type=checkbox name=clone_costs_p value=1 @clone_costs_p_selected@>
	<%= [im_gif help [lang::message::lookup "" intranet-core.CloneProjectCosts_Help "Clone financial items belonging to the template?"]] %> &nbsp; 
      </td>
    </tr>
    <tr> 
      <td><%= [lang::message::lookup "" intranet-core.CloneProjectFiles "Clone Project Files?"] %> &nbsp;</td>
      <td> 
	<input type=checkbox name=clone_files_p value=1 @clone_files_p_selected@>
	<%= [im_gif help [lang::message::lookup "" intranet-core.CloneProjectFiles_Help "Clone the filestorage files associated with this project?"]] %> &nbsp; 
      </td>
    </tr>

    <tr> 
      <td><%= [lang::message::lookup "" intranet-core.CloneForumTopics "Clone Project Forum Topics?"] %> &nbsp;</td>
      <td> 
	<input type=checkbox name=clone_forum_topics_p value=1 @clone_forum_topics_p_selected@>
	<%= [im_gif help [lang::message::lookup "" intranet-core.CloneForumTopics_Help "Clone forum topics associated with this project?"]] %> &nbsp; 
      </td>
    </tr>

    <tr> 
      <td><%= [lang::message::lookup "" intranet-core.CloneProjectMembers "Clone Project Members?"] %> &nbsp;</td>
      <td> 
	<input type=checkbox name=clone_members_p value=1 @clone_members_p_selected@>
	<%= [im_gif help [lang::message::lookup "" intranet-core.CloneProjectMembers_Help "Clone Project Members?"]] %> &nbsp; 
      </td>
    </tr>

    <tr> 
      <td><%= [lang::message::lookup "" intranet-core.CloneProjectSubprojects "Clone Project Subprojects?"] %> &nbsp;</td>
      <td> 
	<input type=checkbox name=clone_subprojects_p value=1 @clone_subprojects_p_selected@>
	<%= [im_gif help [lang::message::lookup "" intranet-core.CloneProjectSubprojects_Help "Clone Subprojects?"]] %> &nbsp; 
      </td>
    </tr>
    <tr> 
      <td><%= [lang::message::lookup "" intranet-core.CloneProjectTimesheetTasks "Clone Project Gantt Tasks?"] %> &nbsp;</td>
      <td> 
	<input type=checkbox name=clone_timesheet_tasks_p value=1 @clone_timesheet_tasks_p_selected@>
	<%= [im_gif help [lang::message::lookup "" intranet-core.CloneProjectTimesheetTasks_Help "Clone timesheet (Gantt) tasks associated with this project?"]] %> &nbsp; 
      </td>
    </tr>
    <tr> 
      <td><%= [lang::message::lookup "" intranet-core.CloneProjectTransTasks "Clone Project Translation Tasks?"] %> &nbsp;</td>
      <td> 
	<input type=checkbox name=clone_trans_tasks_p value=1 @clone_trans_tasks_p_selected@>
	<%= [im_gif help [lang::message::lookup "" intranet-core.CloneProjectTransTasks_Help "Clone translation  tasks associated with this project?"]] %> &nbsp; 
      </td>
    </tr>
    <tr> 
      <td valign=top> 
	<div align=right>&nbsp; </div>
      </td>
      <td> 
	  <p> 
	    <input type=submit value="@button_text@" name=submit2>
	    <%= [im_gif help "Create the new folder structure"] %>
	  </p>
      </td>
    </tr>
  </table>
</form>
