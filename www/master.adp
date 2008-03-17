<% if {![info exists header_stuff] } { set header_stuff {} } %>
<% if {![info exists title]} { set title "" } %>
<% if {![info exists main_navbar_label]} { set main_navbar_label "" } %>
<% if {![info exists sub_navbar]} { set sub_navbar "" } %>

<% set oacs_version [util_memoize "db_string o_ver \"select substring(max(version_name),1,3) from apm_package_versions where package_key = 'acs-kernel'\""] %>


<if @oacs_version@ eq "5.4">
        <master src=/www/site-compat>
        <%= [im_header_oacs54 $title $header_stuff] %>
</if>
<else>
        <%= [im_header $title $header_stuff] %>
</else>


<%= [im_navbar $main_navbar_label] %>
<%= $sub_navbar %>

<div id="slave">
<div id="slave_content">
<!-- intranet/www/po-master.adp before slave -->
<slave>
<!-- intranet/www/po-master.adp after slave -->
</div>
</div>

<%= [im_footer] %>

