<master src="../master">
<property name=title>Email sent</property>
<property name="context">@context;noquote@</property>

<p>
@first_names@ @last_name@ has been notified.
</p>
<p>
<ul>
<!-- <li>Return to <a href="@referer@">user administration</a></li> -->

<li>Return to <a href="/intranet/users/">user administration</a></li>
<li>View administrative page for newly created user, 
    <a href="/intranet/users/view?@export_vars@">@first_names@ @last_name@</a></li>
</ul>
</p>

