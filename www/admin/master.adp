<%= [im_header $title] %>
<%= [im_navbar "admin"] %>
<br>
<% if {![info exists admin_navbar_label]} { set admin_navbar_label "" } %>
<%= [im_admin_navbar $admin_navbar_label] %>
<slave>
<%= [im_footer] %>
