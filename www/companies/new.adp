<if 1 eq @show_master_p@>
    <master src="../master">
</if>
<else>
<head>
    <%=[im_header -no_head_p 1 -no_master_p 1]%>
</head>
</else>

<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">companies</property>

<formtemplate id="company"></formtemplate>
