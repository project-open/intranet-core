<master src="../master">
<property name="title">#intranet-core.Offices#</property>
<property name="context">#intranet-core.context#</property>
<property name="main_navbar_label">offices</property>
<property name="sub_navbar">@office_navbar_html;noquote@</property>

<div class="filter-list">
   <div class="filter">
      <div class="filter-block">
         <div class="filter-title">
            #intranet-core.Filter_Offices#
         </div>
         @filter_html;noquote@
      </div>
      <if @admin_html@ ne "">
      <div class="filter-block">
         <div class="filter-title">
            #intranet-core.Admin_Offices#
         </div>
         <ul>
            @admin_html;noquote@
         </ul>
      </div>
      </if>
   </div>

   <div class="fullwidth-list">
      <%= [im_box_header $page_title] %>
         <table>
            <%= $table_header_html %>
            <%= $table_body_html %>
            <%= $table_continuation_html %>
         </table>
     <%= [im_box_footer] %>
   </div>
   <div class="filter-list-footer"></div>

</div>


