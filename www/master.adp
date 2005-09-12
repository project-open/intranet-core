<% if {![info exists title]} { set title "" } %>
<%= [im_header $title] %>
<% if {![info exists main_navbar_label]} { set main_navbar_label "" } %>
<%= [im_navbar $main_navbar_label] %>


<!-- intranet/www/master.adp before slave -->
<slave>
<!-- intranet/www/master.adp after slave -->

<%= [im_footer] %>
