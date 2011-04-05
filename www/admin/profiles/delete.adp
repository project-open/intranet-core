<master src=../master>

<h1>Are you sure you want to delete a profile?</h1>

<p>
This will permanently delete a profile and all associated
configuration.
</p>
<p>
<font color=red>
Please choose this option only if you know what you do
and then only to to cleanup demo data during the initial 
configuration of the system.<br>
System groups such as "Employees" or "P/O Admins" have been
excluded from this list. Deleting these groups could cause
serious issues to your system.
</font>
</p>

<form action="delete-2" method=POST>
<ul>
@select_html;noquote@
</ul>
<input type=submit name=Submit>
</form>

