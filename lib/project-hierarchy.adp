<if @subproject_filtering_enabled_p@ eq 1>
  <table class="table_component_clean">
    <form action="@current_url;noquote@" method=GET>
      <input type=hidden name=project_id value=@project_id@>
      <tr>
        <td class=form-label>
	  @filter_name;noquote@
        </td>
        <td class=form-widget>
	  @filter_select;noquote@
          <input type=submit value="Go">
        </td>
     </tr>
    </form>
  </table>
</if>
<table cellpadding=2 cellspacing=2 border=0>
  <tr>
    <multiple name=table_headers>
      <td class=rowtitle>@table_headers.col_txt;noquote@</td>
    </multiple>
  </tr>
  @table_body_html;noquote@
</table>
