<!-- packages/intranet-core/www/projects/new.adp -->
<!-- @author Juanjo Ruiz (juanjoruizx@yahoo.es) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="../master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">projects</property>

<form enctype="multipart/form-data" method=POST action="upload-projects-2.tcl">
<%= [export_form_vars return_url] %>
    <table border=0>
	<tr> 
	<td>Filename</td>
	<td> 
	  <input type=file name=upload_file size=30>
	<%= [im_gif help "Use the &quot;Browse...&quot; button to locate your file, then click &quot;Open&quot;."] %>
	</td>
	</tr>
	<tr> 
	<td></td>
	<td><input type=submit value="Submit and Upload"></td>
	</tr>
    </table>
</form>

<table border=0 cellspacing=0 cellpadding=1 width="70%">
<tr><td>

<p><font color=red>
Please read carefully the following text. 
</font></p>

<p>
Importing data into a system like 
<span class=brandsec>&#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&#91;</span>
is not an easy task, because @po;noquote@ employes tight rules 
about the contents of fields and the relationship between fields.
So please be prepared to spend some time to "massage" your data,
until it will fit into @po;noquote@.
</p>


<h2>Importing Projects</h2>

<p>
To import your projects, you will have to go through the following steps:
<br>&nbsp;
</p>
<ol>
<li><a href="/intranet/admin/backup/pg_dump">Backup your data</a> before performing any import.
    <br>&nbsp;
<li><a href="/intranet/projects/upload-projects-sample.csv">Download a sample CSV project sheet</a>.
    <br>&nbsp;
<li>Edit the CVS in Excel or a similar tool to add your projects.
    <br>&nbsp;
<li>Import your CSV into @po;noquote@ using the form above.
    <br>&nbsp;
<li>Observe the error messages on the import screen.
    <br>&nbsp;
<li>Correct the errors.
    <br>&nbsp;
<li>Continue with 4.
    <br>&nbsp;
</ul>

