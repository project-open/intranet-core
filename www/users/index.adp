<master src="../master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">user</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>

<div class="filter-list">
   <div class="filter">
      <div class="filter-block">
        <div class="filter-title">
	    #intranet-core.Filter_Users#
        </div>

	<form method=get action='/intranet/users/index' name=filter_form>
	<%= [export_form_vars start_idx order_by how_many letter] %>
	<input type=hidden name=view_name value="user_list">
	<table>
	<tr>
	  <td class="form-label">#intranet-core.User_Types#  &nbsp;</td>
	  <td class="form-widget">
	    <%= [im_select user_group_name $user_types ""] %>
	    <input type=submit value=Go name=submit>
	  </td>
	</tr>
	</table>
	</form>

      </div>
<if @admin_html@ ne "">
      <div class="filter-block">
         <div class="filter-title">
            #intranet-core.Admin_Users#
         </div>
         @admin_html;noquote@
      </div>
</if>

      </div>
   </div> <!-- filter -->

   <div class="fullwidth-list">
      <%= [im_box_header $page_title $list_icons] %>
         <table>
            <%= $table_header_html %>
            <%= $table_body_html %>
            <%= $table_continuation_html %>
         </table>
     <%= [im_box_footer] %>
   </div>
   <div class="filter-list-footer"></div>

</div>