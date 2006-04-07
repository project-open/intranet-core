<master src="../master">
<property name="context">@context;noquote@</property>
<property name="title">@page_title@</property>
<property name="admin_navbar_label">admin_users</property>

<h1><font color=red>@page_title@</font></h1>

<table width="60%">
<tr><td>
<p>
This page allows you to delete all demo users in the system.
This is useful if you want to start using a preconfigured
system for production purposes.
</p>
<p>
The system administrators have been excluded from this list,
so you can safely press the checkbox in the header just below
this text line in order to select all users.
</p>
</td></tr>
</table>

<p>
<listtemplate name="user_list"></listtemplate>



