<master src="../master">
<property name="context">@context;literal@</property>
<property name="doc(title)">@page_title;literal@</property>
<property name="admin_navbar_label">admin_projects</property>

<h1><font color=red>@page_title@</font></h1>

<table width="60%">
<tr><td>
<p>
This page allows you to delete all orphan tasks in the system.
Orphan tasks do not have a relationship with an existing project. They are probably not linked anywhere but can be accessed through the GUI. 
</p>
</td></tr>
</table>

<p>
<listtemplate name="task_list"></listtemplate>
