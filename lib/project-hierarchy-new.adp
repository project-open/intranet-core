<if @subproject_filtering_enabled_p@>
  <table class="table_component_clean">
    <form action="@current_url;noquote@" method=GET>
      <input type="hidden" name="project_id" value="@project_id@">
      <tr>
	<td class=form-label>#intranet-core.Filter_Status#</td>
        <td class=form-widget>
	  @category_select;noquote@
	  <input type=submit value="Go">
	</td>
      </tr>
    </form>
  </table>
</if>
<table cellpadding=2 cellspacing=2 border=0>
  <tr>
    <td class=rowtitle>@col_txt;noquote@</td>
  </tr>
  <tr @bgcolo;noquote@>
  
  </tr>
  @table_header_html;noquote@
  @table_body_html;noquote@
</table>
    



@html;noquote@

