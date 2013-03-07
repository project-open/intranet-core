<master src="../master">
<property name="title">@page_title@</property>
<property name="main_navbar_label">projects</property>
<property name="left_navbar">@left_navbar_html;noquote@</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>
<property name="show_context_help_p">@show_context_help_p;noquote@</property>

<form action=/intranet/projects/project-action-shift-2 method=POST>
<%= [export_form_vars return_url select_project_id] %>
<table border=0>
<tr>
<td colspan=2>Shift projects forward or backward in time:</td>
</tr>

<tr>
<td colspan=2><input type=input name=shift_period width=20 value="+1w">
</tr>

<tr>
<td><input type=submit>
</tr>

</table>
</form>

<br>&nbsp;<br>

<p>You can specify the shift period in several ways:</p>
<ul>
<li><b>"+10"</b>: Move the project (start and end) 10 days into the future.
<li><b>"-10"</b>: Move the project 10 days into the past.
<li><b>"+2w"</b>: Move the project two weeks into the future.
<li><b>"-2w"</b>: Move the project two weeks into the past.
</ul>