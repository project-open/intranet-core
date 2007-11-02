<%= [im_header $title $header_stuff] %>
<% if {![info exists main_navbar_label]} { set main_navbar_label "" } %>
<%= [im_navbar $main_navbar_label] %>

<div id="slave">
<div id="slave_content">
<!-- intranet/www/po-master.adp before slave -->
<slave>
<!-- intranet/www/po-master.adp after slave -->
</div>
</div>

<%= [im_footer] %>
