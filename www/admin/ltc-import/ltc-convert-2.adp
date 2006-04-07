<master src="../master">
<property name="context">@context;noquote@</property>
<property name="title">@page_title@</property>
<property name="admin_navbar_label">admin_projects</property>

<h1>@page_title@</h1>

<table width="60%">
<tr><td>
<p>

<p>
This page check that the LTC-Organizer tables have been
imported correctly into the database.
</p>

<if @ltc_data_p@>

<h2>LTC-Organiser Data Found</h2>

<form action="ltc-convert-2" method=post>
<center>
<input type=submit value="Import LTC-Organizer Data"
</center>
</form>

</if>
<else>

<h2>No LTC-Organiser Data Found</h2>

<p>
There is not table "CONTACT" in the current database.
This indicates that you haven't (successfully) imported
the LTC-Organiser data into this PostgreSQL database.
Please see the previous page for more details.
</p>

</else>

</td></tr>
</table>

<p>
