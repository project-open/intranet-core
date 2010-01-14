<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="../master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">companies</property>


<h2>@page_title@</h2>

#intranet-core.lt_Confirm_the_nuking_of#
<a href="view?company_id=@company_id@">@company_name@</a>
<p>


First, unless @object_name@ is a test @object_type@, you 
should probably delete this user instead. Deleting marks 
the @object_type@ deleted but leaves intact its
relationship with other objects such as forums, filestorage etc.

<p>
Nuking is a violent irreversible action. 
You are instructing the system to remove the user and any content 
that he or she has contributed to the site. This is generally only 
appropriate in the case of test users and, perhaps, dishonest people 
who've flooded a site with fake crud.
<p>

<center>
<form method=get action=nuke-2>
<input type=hidden name=company_id value="@company_id@">
<input type=submit value="Yes I am sure that I want to delete this @object_type@">
</form>
</center>
