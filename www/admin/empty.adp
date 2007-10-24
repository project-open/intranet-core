<master src="/packages/intranet-core/www/master">
<property name="title">@page_title;noquote@</property>
<property name="admin_navbar_label">admin_home</property>
<property name="extra_footer_stuff_before_end_body">asdf asdf asdf asdf</property>

<h1>@page_title@</h1>


<li>url = <%= [ns_conn url] %>
<li>Host = <%= [ns_set get [ns_conn headers] "Host"] %>


<pre>
@debug;noquote@
</pre>

