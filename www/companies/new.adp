<if 1 eq @show_master_p@>
    <master src="../master">
</if>
<else>
<head>
    <%=[im_header -no_head_p 1 -no_master_p 1]%>
</head>
</else>

<property name="doc(title)">@page_title;literal@</property>
<property name="context">@context_bar;literal@</property>
<property name="main_navbar_label">companies</property>

<formtemplate id="company"></formtemplate>
