<master src="../master">
<property name="doc(title)">@page_title;literal@</property>
<property name="context">@context;literal@</property>
<property name="admin_navbar_label">admin_views</property>

<h2>@page_title@</h2>

<if @message@ not nil>
  <div class="general-message">@message@</div>
</if>

<property name="focus">@focus;literal@</property>
<formtemplate id="view"></formtemplate>

<if @view_id@ not nil>
	<listtemplate name="column_list"></listtemplate>
</if>
