<%= [im_header $title $header_stuff] %>
<% if {![info exists main_navbar_label]} { set main_navbar_label "" } %>
<%= [im_navbar $main_navbar_label] %>
<slave>
<%= [im_footer] %>
