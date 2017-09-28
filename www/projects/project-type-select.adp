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
	<td>	<b><%= [lang::message::lookup "" intranet-core.Project_type_classic_gantt "Classic / Gantt Project"] %>
		<a href="@po_gantt;noquote@" target="_"><img src="/intranet/images/external.png"></a>
		</b><br>
		<%= [im_help_collapsible "<br>
		[lang::message::lookup "" intranet-core.project_type_gantt_short_blurb "
		A Gantt Project is defined by a number of activities with a planned
		start- and end date. \]project-open\[ will show a Gantt
		Editor that allows you to graphically edit the project
		schedule.<br>
		Classical / Gantt projects allow for tight progress tracking, 
		financial controlling, resource management and other."]"] %><br>
		@gantt_project_subtypes_html;noquote@
	</td>
	</tr>
	</table>
</td>
<td>
	<a href="@po_gantt;noquote@" target="_">
	<img  width=442 height=158 src="/intranet/images/project-types/pm-classic.png" title="@click_me_l10n@"></a>
</td>
</tr>
<tr><td colspan=2><hr style="height:1px;border:none;color:#333;background-color:#333;" /></td></tr>
<tr valign="top">
<td>
	<table cellspacing="0" cellpadding="0">
	<tr valign=top>
	<td width=25></td>
	<td>	<b><%= [lang::message::lookup "" intranet-core.Project_type_agile "Agile Project"] %>
		<a href="@po_agile;noquote@" target="_"><img src="/intranet/images/external.png"></a>
		</b><br>
		<%= [im_help_collapsible "<br>
		[lang::message::lookup "" intranet-core.Project_type_agile_short_blurb "
		An Agile Project is defined by a backlog and a number 
		of sprints or agile project phases.<br>
		Agile projects allow to react flexibly to changes, but provide
		less detailed planning information, compared to Gantt Projects."] "] %>
		@agile_project_subtypes_html;noquote@
	</td>
	</tr>
	</table>
</td>
<td>
	<a href="@po_agile;noquote@" target="_">
	<img width=442 height=158 src="/intranet/images/project-types/pm-agile.png" title="@click_me_l10n@"></a>
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
	<td>	<b><%= [lang::message::lookup "" intranet-core.Project_type_mixed "Mixed Methodology Project"] %>
		<a href="@po_mixed;noquote@" target="_"><img src="/intranet/images/external.png"></a>
		</b><br>
		<%= [im_help_collapsible "<br>
		[lang::message::lookup "" intranet-core.Project_type_mixed_short_blurb "
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
		for flexibility in the agile phases."] "] %>
	</td>
	</tr>
	</table>
</td>
<td>
	<a href="@po_mixed;noquote@" target="_">
	<img  width=442 height=158 src="/intranet/images/project-types/pm-mixed.png" title="@click_me_l10n@"></a>
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
	<td>	<b><%= [lang::message::lookup "" intranet-core.Project_type_ticket_container "Ticket Container"] %>
		<a href="@po_maint;noquote@" target="_"><img src="/intranet/images/external.png"></a>
		</b><br>
		<%= [im_help_collapsible "<br>
		[lang::message::lookup "" intranet-core.Project_type_ticket_container_short_blurb "
		A Ticket Container serves as a tracker for a number of tickets
		of a specific type. A Ticket Container may be a top-level project,
		or maybe a sub-project of a Gantt Project.<br>
		Ticket Containers handle permissions, timesheet logging and
		financial controlling for the included tickets."] "]%>
	</td>
	</tr>
	</table>
</td>
<td>
	<a href="@po_maint;noquote@" target="_">
	<img  width=442 height=158 src="/intranet/images/project-types/pm-maintenance.png" title="@click_me_l10n@"></a>
</td>
</tr>
<tr><td colspan=2><hr style="height:1px;border:none;color:#333;background-color:#333;" /></td></tr>



<if @translation_p@ gt 0>
<tr valign=top>
<td width="500">
	<table cellspacing="0" cellpadding="0">
	<tr valign=top>
	<td width=22>
		<input type="radio" name="project_type_id" value="2500" onclick="window.scrollTo(0, document.body.scrollHeight);">
	</td>
	<td>	<b><%= [lang::message::lookup "" intranet-core.Project_type_translation "Translation Project"] %>
		<a href="@po_trans;noquote@" target="_"><img src="/intranet/images/external.png"></a>
		</b><br>
		<%= [im_help_collapsible "<br>
		[lang::message::lookup "" intranet-core.project_type_trans_short_blurb "
		A Translation Project is defined by a number of documents to be translated."]"] %><br>
		@trans_project_subtypes_html;noquote@
	</td>
	</tr>
	</table>
</td>
<td>
	<a href="@po_gantt;noquote@" target="_">
	<!-- <img  width=442 height=158 src="/intranet/images/project-types/pm-classic.png" title="@click_me_l10n@"></a> -->
</td>
</tr>
<tr><td colspan=2><hr style="height:1px;border:none;color:#333;background-color:#333;" /></td></tr>
</if>




<tr valign=top>
<td>
	<table cellspacing="0" cellpadding="0">
	<tr valign=top>
	<td></td>
	<td>	<b><%= [lang::message::lookup "" intranet-core.Project_type_other "Other"] %></b><br>
		<%= [lang::message::lookup "" intranet-core.Project_type_agile_short_blurb "
		The following are project types for specific purposes."] %>
	</td>
	</tr>

	<tr valign=top>
	<td>	
	<input type="radio" name="project_type_id" value="<%= [im_project_type_program] %>" onclick="window.scrollTo(0, document.body.scrollHeight);">
	</td>
	<td>	<b><%= [lang::message::lookup "" intranet-core.Project_type_program Program] %></b><br>
		<%= [lang::message::lookup "" intranet-core.Project_type_program_short_blurb "
		A program or \"programme\" groups a number of projects that usually have a common purpose."] %>
	</td>
	</tr>

	<tr valign=top>
	<td>	
	<input type="radio" name="project_type_id" value="<%= [im_project_type_ticket_container] %>" onclick="window.scrollTo(0, document.body.scrollHeight);">
	</td>
	<td>	<b><%= [lang::message::lookup "" intranet-core.Project_type_release_project "Release Project"] %></b><br>
		<%= [im_help_collapsible "<br>
		[lang::message::lookup "" intranet-core.Project_type_release_short_blurb "
		Groups a number of software release items and provides 
		a testing workflow that determines how these items
		become part of a release to a critical production server."] "] %>
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
