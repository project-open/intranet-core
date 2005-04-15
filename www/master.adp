<% if {![info exists title]} { set title "" } %>
<%= [im_header $title] %>
<% if {![info exists main_navbar_label]} { set main_navbar_label "" } %>
<%= [im_navbar $main_navbar_label] %>
<slave>
<%= [im_footer] %>
