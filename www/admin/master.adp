<master src=/www/site-compat>

<property name="on_load">javascript:initPortlet();</property>
<property name="header_stuff">@extra_stuff_for_document_head;noquote@</property>
<property name="title">@title;noquote@</property>
<%= [im_header -no_head_p "1" $title] %>
<%= [im_navbar "admin"] %>
<br>
<% if {![info exists admin_navbar_label]} { set admin_navbar_label "" } %>
<%= [im_admin_navbar $admin_navbar_label] %>
<slave>
<%= [im_footer] %>
