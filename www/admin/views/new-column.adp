<master src="../master">
<property name="title">@page_header@</property>
<property name="context">@context;noquote@</property>
<property name="admin_navbar_label">admin_views</property>
<property name="focus">@focus;noquote@</property>

<h1>@page_title;noquote@</h1>

<if @message@ not nil>
  <div class="general-message">@message@</div>
</if>

<formtemplate id="column"></formtemplate>

