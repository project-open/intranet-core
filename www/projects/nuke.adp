<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="../master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">projects</property>


<h2>@page_title@</h2>

<p>
#intranet-core.lt_Confirm_the_nuking_of#
<a href="one?project_id=@project_id@">@project_name@</a>.
Nuking is a violent irreversible action. 

</p><br>

<listtemplate name="@list_id@"></listtemplate>

<br>
<p>
First, unless @object_name@ is a test @object_type@, you 
should probably set the status of this project as 'deleted'
instead. This way, the project won't appear in the rest of
the system anymore, but associated information will kept
intact.
</p><br>

<center>
<form method=get action=nuke-2>
<input type=hidden name=project_id value="@project_id@">
<input type=submit value="Yes I am sure that I want to delete this @object_type@">
</form>
</center>
