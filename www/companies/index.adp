<master src="../master">
<property name="title">#intranet-core.Companies#</property>
<property name="context">#intranet-core.context#</property>
<property name="main_navbar_label">companies</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>


<div class="filter-list">
   <div class="filter">
      <div class="filter-block">
         <div class="filter-title">
	    #intranet-core.Filter_Companies#
         </div>
         <if @filter_advanced_p@>
            <formtemplate id="company_filter"></formtemplate>
         </if>
         <else>
            <form method="get" action="/intranet/companies/index" name="filter_form">
	       <%= [export_form_vars start_idx order_by how_many letter view_name] %>
	       <table border="0" cellpadding="0" cellspacing="0">
               <if @view_companies_all_p@>
	          <tr>
	             <td>#intranet-core.View_1#  &nbsp;</td>
	             <td><%= [im_select view_type $view_types ""] %></td>
	          </tr>
	          <tr>
	             <td>#intranet-core.Company_Status_1#  &nbsp;</td>
	             <td><%= [im_category_select -include_empty_p 1 "Intranet Company Status" status_id $status_id] %></td>
	          </tr>
               </if>
	       <tr>
	          <td>#intranet-core.Company_Type_1#  &nbsp;</td>
	          <td>
	             <%= [im_category_select -include_empty_p 1 "Intranet Company Type" type_id $type_id] %>
	             <input type=submit value=Go name=submit>
	          </td>
	      </tr>
	      </table>
	    </form>
         </else>
      </div>

      <hr/>
      <div class="filter-block">
         <div class="filter-title">
            #intranet-core.Admin_Companies#
         </div>
         @admin_html;noquote@
      </div>

      <hr/>
      <div class="filter-block">
      <%= [im_navbar_tree -label "main"] %>
      </div>

   </div>

   <div class="fullwidth-list">
      <%= [im_box_header [_ intranet-core.Companies]] %>
         <table>
            <%= $table_header_html %>
            <%= $table_body_html %>
            <%= $table_continuation_html %>
         </table>
     <%= [im_box_footer] %>
   </div>
   <div class="filter-list-footer"></div>

</div>


