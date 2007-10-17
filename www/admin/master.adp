<%= [im_header $title] %>
<%= [im_navbar "admin"] %>
<% if {![info exists admin_navbar_label]} { set admin_navbar_label "" } %>
<%= [im_admin_navbar $admin_navbar_label] %>
<div id="slave">
<div id="slave_content">
<!-- intranet/www/adnin/master.adp before slave -->
<slave>
<!-- intranet/www/admin/master.adp after slave -->
</div>
</div>
<%= [im_footer] %>
