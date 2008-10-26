<% if {![info exists admin_navbar_label]} { set admin_navbar_label "" } %>
<% if {![info exists title]} { set title [lang::message::lookup intranet-core.Admin "Admin"] } %>
<% if {![info exists context]} { set context "" } %>

<master src=../master>
<property name="title">@title;noquote@</property>
<property name="admin_navbar_label">@admin_navbar_label;noquote@</property>
<property name="context">@context;noquote@</property>
      <div class='filter-list'>
	 <a id="sideBarTab" href="#"><img id="sideBarTabImage" border="0" title="sideBar" alt="sideBar" src="/intranet/images/navbar_saltnpepper/slide-button-active.gif"/></a>
         <%= [im_admin_navbar $admin_navbar_label] %>
         <div id="admin-content" class="fullwidth-list">
            <!-- intranet/www/admin/master.adp before slave -->
            <slave>
            <!-- intranet/www/admin/master.adp after slave -->
	 </div>
      </div>
