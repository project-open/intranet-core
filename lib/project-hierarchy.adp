<if @read_p@ eq "1">

<script type="text/javascript" <if @::__csp_nonce@ not nil>nonce="@::__csp_nonce;literal@"</if>>
window.addEventListener('load', function() { 
     document.getElementById('list_check_all').addEventListener('click', function() { acs_ListCheckAll('hierarchy_project_id', this.checked) });
});
</script>


<if @subproject_filtering_enabled_p@ eq 1>
  <form action="@return_url;noquote@" method=GET>
  <input type="hidden" name="project_id" value="@project_id@">
  <span style="white-space: nowrap; vertical-align: middle">@filter_name;noquote@: @filter_select;noquote@ &nbsp; <input type="submit" value="Go"></span>
  <br><br>
  </form>
</if>

<form action=/intranet/projects/project-action>
<%= [export_vars -form {return_url}] %>
<table cellpadding="2" cellspacing="2" border="0">
  <tr>
    <multiple name=table_headers>
      <td class=rowtitle>@table_headers.col_txt;noquote@</td>
    </multiple>
  </tr>
  @table_body_html;noquote@
  @table_continuation_html;noquote@
</table>
</form>

</if>
