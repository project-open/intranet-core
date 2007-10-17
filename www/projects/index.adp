<master src="../master">
<property name="title">@page_title@</property>
<property name="context">#intranet-core.context#</property>
<property name="main_navbar_label">projects</property>
<property name="sub_navbar">@project_navbar_html;noquote@</property>

<div class="filter-list">
   <div class="filter">
      <div class="filter-block">
         <div class="filter-title">
            #intranet-core.Filter_Projects#
         </div>
         <if @filter_advanced_p@>
            <formtemplate id=@form_id@></formtemplate>
         </if>
         <else>
            @filter_html;noquote@
         </else>
      </div>
      <hr/>
      <div class="filter-block">
         <div class="filter-title">
            #intranet-core.Admin_Projects#
         </div>
         @admin_html;noquote@
      </div>
   </div>

   <div class="fullwidth-list">
      <%= [im_box_header "Projects"] %>
         <table>
            <%= $table_header_html %>
            <%= $table_body_html %>
            <%= $table_continuation_html %>
         </table>
     <%= [im_box_footer] %>
   </div>
   <div class="filter-list-footer"></div>

</div>


