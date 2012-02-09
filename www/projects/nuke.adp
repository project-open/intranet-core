<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="../master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">projects</property>


<h2>@page_title@</h2>

<p>
#intranet-core.lt_Confirm_the_nuking_of#
<a href="@project_url_org@">@project_name_org@</a>.
<%= [lang::message::lookup "" intranet-core.Nuking_is_a_violent_irreversible_action "Nuking is a violent irreversible action."] %>

</p><br>

<listtemplate name="@list_id@"></listtemplate>

<br>
<p>
<%= [lang::message::lookup "" intranet-core.You_shoud_change_status_to_deleted "
First, unless @object_name@ is a test @object_type@, you 
should probably set the status of this project as 'deleted'
instead."] %><br>

<%= [lang::message::lookup "" intranet-core.This_way_the_project_wont_appear "
This way, the project won't appear in the rest of
the system anymore, but associated information will kept
intact."] %>
</p><br>

