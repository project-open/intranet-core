<master src=/www/site-compat>

<property name="on_load">javascript:initPortlet();</property>
<property name="header_stuff">@extra_stuff_for_document_head;noquote@</property>
<property name="title">@title;noquote@</property>
<property name="focus">@focus;noquote@</property>

<%= [im_header -no_head_p "1" $title $header_stuff] %>
<% if {![info exists main_navbar_label]} { set main_navbar_label "" } %>
<%= [im_navbar $main_navbar_label] %>

<!-- intranet/www/po-master.adp before slave -->
<slave>
<!-- intranet/www/po-master.adp after slave -->

<%= [im_footer] %>
