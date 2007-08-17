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
<b>Deleting Admins</b>: Users with the system administration role 
have been intentionally excluded from the list below
in order to avoid users to lock themselves out of the system.
In order to delete a SysAdmin user please to go to the tab "Users",
select "User Types" = "P/O Admins" and edit the users to remove their
admin rights.
</p>
<p>
<b>Deleting User "System Administrator"</b>: This is the only user that 
you can never delete because it owns a number of system objects. 
However, you can rename it's name and email address, so that you 
can use this account for yourself.
</p>
</td></tr>
</table>

<p>
<listtemplate name="user_list"></listtemplate>



