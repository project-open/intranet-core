<master src="/packages/intranet-core/www/master">
<property name="doc(title)">#intranet-core.Projects#</property>
<property name="main_navbar_label">projects</property>
<property name="sub_navbar">@sub_navbar;literal@</property>
<property name="show_context_help_p">@show_context_help_p;literal@</property>


<script type="text/javascript" <if @::__csp_nonce@ not nil>nonce="@::__csp_nonce;literal@"</if>>
window.addEventListener('load', function() { 
     document.getElementById('start_calendar').addEventListener('click', function() { showCalendarWithDateWidget('start', 'y-m-d'); });
     document.getElementById('end_calendar').addEventListener('click', function() { showCalendarWithDateWidget('end', 'y-m-d'); });
});
</script>


<formtemplate id="@form_id@"></formtemplate>
