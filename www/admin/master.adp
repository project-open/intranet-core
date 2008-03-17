<% if {![info exists admin_navbar_label]} { set admin_navbar_label "" } %>
<master src=../master>

<div id="slave">
   <div id="slave_content">
      <div class='filter-list'>
         <%= [im_admin_navbar $admin_navbar_label] %>
         <div id="admin-content" class="fullwidth-list">
            <!-- intranet/www/admin/master.adp before slave -->
            <slave>
            <!-- intranet/www/admin/master.adp after slave -->
	 </div>
      </div>
   </div>
</div>
