<master src=../master>

<property name="on_load">javascript:initPortlet();</property>
<property name="title">@title;noquote@</property>
<br>
<% if {![info exists admin_navbar_label]} { set admin_navbar_label "" } %>
<%= [im_admin_navbar $admin_navbar_label] %>
<slave>
