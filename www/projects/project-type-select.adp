<master>
<property name="doc(title)">@page_title;literal@</property>
<property name="main_navbar_label"></property>

<table cellspacing="0" cellpadding="0">
<tr><td width="950">
<%= [im_box_header $page_title] %>

<form action='@return_url;noquote@' method=POST>
<%= [export_vars -form {user_id_from_search project_id}] %>
@pass_through_html;noquote@


<table cellspacing="0" cellpadding="0">
<tr valign=top>
<td width="500">
	<table cellspacing="0" cellpadding="0">
	<tr valign=top>
	<td width=22>
		<input type="radio" name="project_type_id" value="2501" onclick="window.scrollTo(0, document.body.scrollHeight);">
	</td>
	<td>	<b>Classic / Gantt Project</b><br>
		<%= [im_help_collapsible "<br>
		A Gantt Project is defined by a number of activities with a planned
		start- and end date. \]project-open\[ will show a Gantt
		Editor that allows you to graphically edit the project
		schedule.<br>
		Classical / Gantt projects allow for tight progress tracking, 
		financial controlling, resource management and other."] %><br>
		@gantt_project_subtypes_html;noquote@
	</td>
	</tr>
	</table>
</td>
<td>
	<a href="http://www.project-open.net/en/project-type-classic&system_id=<%= [im_system_id]%>" target="_">
	<img  width=442 height=158 src="/intranet/images/project-types/pm-classic.png" title="Click me for more information"></a>
</td>
</tr>
<tr><td colspan=2><hr style="height:1px;border:none;color:#333;background-color:#333;" /></td></tr>
<tr valign="top">
<td>
	<table cellspacing="0" cellpadding="0">
	<tr valign=top>
	<td width=25></td>
	<td>	<b>Agile Project</b><br>
		<%= [im_help_collapsible "<br>
		An Agile Project is defined by a backlog and a number 
		of sprints or agile project phases.<br>
		Agile projects allow to react flexibly to changes, but provide
		less detailed planning information, compared to Gantt Projects."] %>
		@agile_project_subtypes_html;noquote@
	</td>
	</tr>
	</table>
</td>
<td>
	<a href="http://www.project-open.net/en/project-type-agile&system_id=<%= [im_system_id]%>" target="_">
	<img width=442 height=158 src="/intranet/images/project-types/pm-agile.png" title="Click me for more information"></a>
</td>
</tr>
<tr><td colspan=2><hr style="height:1px;border:none;color:#333;background-color:#333;" /></td></tr>
<tr valign="top">
<td>
	<table cellspacing="0" cellpadding="0">
	<tr valign=top>
	<td width=22>	
	<input type="radio" name="project_type_id" value="2501" onclick="window.scrollTo(0, document.body.scrollHeight);">
	</td>
	<td>	<b>Mixed Methodology Project</b><br>
		<%= [im_help_collapsible "<br>
		A \"mixed project\" consists of a Gantt Project, but part of 
		the work is done within agile sprints. To setup a mixed project please:
		<ol>
		<li>Create a main project of type Gantt Project.
		<li>Add a \"Backlog\" sub-project of type \"Ticket Container\".
		<li>Add \"Sprint 1\" sub-projects of type \"SCRUM Sprint\".
		<li>Click on \"Sprint 1\" and then on \"add existing items\"
		    in order to add user stories or tasks to the sprints.
		    You can include both Gantt tasks and user stories
		    as sprint items.
		</ol>
		Mixed projects allow for project tracking, financial controlling
		and resource management on the coarse-grain level, but allow
		for flexibility in the agile phases."] %>
	</td>
	</tr>
	</table>
</td>
<td>
	<a href="http://www.project-open.net/en/project-type-mixed&system_id=<%= [im_system_id]%>" target="_">
	<img  width=442 height=158 src="/intranet/images/project-types/pm-mixed.png" title="Click me for more information"></a>
</td>
</tr>
<tr><td colspan=2><hr style="height:1px;border:none;color:#333;background-color:#333;" /></td></tr>
<tr valign=top>
<td>
	<table cellspacing="0" cellpadding="0">
	<tr valign=top>
	<td>
	<input type="radio" name="project_type_id" value="<%= [im_project_type_ticket_container] %>" onclick="window.scrollTo(0, document.body.scrollHeight);">
	</td>
	<td>	<b>Ticket Container</b><br>
		<%= [im_help_collapsible "<br>
		A Ticket Container serves as a tracker for a number of tickets
		of a specific type. A Ticket Container may be a top-level project,
		or maybe a sub-project of a Gantt Project.<br>
		Ticket Containers handle permissions, timesheet logging and
		financial controlling for the included tickets."] %>
	</td>
	</tr>
	<tr valign=top>
	<td>	
	<input type="radio" name="project_type_id" value="<%= [im_project_type_ticket_container] %>" onclick="window.scrollTo(0, document.body.scrollHeight);">
	</td>
	<td>	<b>Release Project</b><br>
		<%= [im_help_collapsible "<br>
		Groups a number of software release items and provides 
		a testing workflow that determines how these items
		become part of a release to a critical production server."] %>
	</td>
	</tr>
	</table>
</td>
<td>
	<a href="http://www.project-open.net/en/project-type-maintenance&system_id=<%= [im_system_id]%>" target="_">
	<img  width=442 height=158 src="/intranet/images/project-types/pm-maintenance.png" title="Click me for more information"></a>
</td>
</tr>
<tr><td colspan=2><hr style="height:1px;border:none;color:#333;background-color:#333;" /></td></tr>
<tr valign=top>
<td>
	<table cellspacing="0" cellpadding="0">
	<tr valign=top>
	<td></td>
	<td>	<b>Other</b><br>
		The following are project types for specific purposes.
	</td>
	</tr>

	<tr valign=top>
	<td>	
	<input type="radio" name="project_type_id" value="<%= [im_project_type_program] %>" onclick="window.scrollTo(0, document.body.scrollHeight);">
	</td>
	<td>	<b>Program</b><br>
		A program or "programme" groups a number of projects that usually have a common purpose.
	</td>
	</tr>

	</table>
</td>
<td></td>
</tr>
<tr><td colspan=2><hr style="height:1px;border:none;color:#333;background-color:#333;" /></td></tr>
<tr valign="top">
    <table cellspacing="0" cellpadding="0">
    <tr valign=top>
    <td width=22></td>
    <td align=left>
	<input type="submit" value='<%= [lang::message::lookup "" intranet-core.Create_Project "Create Project"] %>'>
    </td>
    </tr>
    </table>
</tr>
</table>


</form>

<%= [im_box_footer] %>
</td></tr>
</table>
