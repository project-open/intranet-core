<% if {![info exists header_stuff] } { set header_stuff {} } %>
<% if {![info exists title]} { set title "" } %>
<% if {![info exists main_navbar_label]} { set main_navbar_label "" } %>
<% if {![info exists sub_navbar]} { set sub_navbar "" } %>

<% set oacs_version [util_memoize "db_string o_ver \"select substring(max(version_name),1,3) from apm_package_versions where package_key = 'acs-kernel'\""] %>

<%= [im_header $title $header_stuff] %>
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
