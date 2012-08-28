<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="../master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">projects</property>


<h2>@page_title@</h2>

<if 0 eq @result_len@>
We have nuked the project.
<p>
Please continue with the tabs above.
</if>
<else>
We have found errors nuking projects:
<pre>
@result;noquote@
</pre>
</else>

