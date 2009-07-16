<master src="../master">
  <property name="title">@page_title@</property>
  <property name="context">@context@</property>
  <property name="main_navbar_label">admin</property>
  <property name="focus">@page_focus;noquote@</property>
  <property name="admin_navbar_label">admin_exchange_rates</property>
  <property name="left_navbar">@left_navbar_html;noquote@</property>


<if @show_add_new_category_p@>

@category_list_html;noquote@

</if>
<else>

<listtemplate name="categories"></listtemplate>

</else>
