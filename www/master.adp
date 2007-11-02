<% if {![info exists title]} { set title "" } %>
<% if {![info exists sub_navbar]} { set sub_navbar "" } %>
<%= [im_header $title] %>
<% if {![info exists main_navbar_label]} { set main_navbar_label "" } %>
<%= [im_navbar $main_navbar_label] %>

<%= $sub_navbar %>

<div id="slave">
<div id="slave_content">
<!-- intranet/www/master.adp before slave -->
<slave>
<!-- intranet/www/master.adp after slave -->
</div>
</div>

<%= [im_footer] %>
