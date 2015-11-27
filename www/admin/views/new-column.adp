<master src="../master">
<property name="doc(title)">@page_header;literal@</property>
<property name="context">@context;literal@</property>
<property name="admin_navbar_label">admin_views</property>
<property name="focus">@focus;literal@</property>

<h1>@page_title;noquote@</h1>

<if @message@ not nil>
  <div class="general-message">@message@</div>
</if>

<formtemplate id="column"></formtemplate>

