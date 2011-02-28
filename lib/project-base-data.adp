<table border=0>
  <tr> 
    <td>#intranet-core.Project_name#</td>
    <td>@project_name;noquote@</td>
  </tr>
  <if @parent_id@ not nil>
    <tr> 
      <td>#intranet-core.Parent_Project#</td>
      <td>
        <a href=/intranet/projects/view?project_id=@parent_id@>@parent_name;noquote@</a>
      </td>
    </tr>
  </if>
  <tr> 
    <td>#intranet-core.Project_Nr#</td>
    <td>@project_nr@</td>
  </tr>
  <if @enable_project_path_p@ eq 1>
    <tr> 
      <td>#intranet-core.Project_Path#</td>
      <td>@project_path;noquote@</td>
    </tr>
  </if>
  @im_company_link_tr;noquote@
  <tr> 
    <td>#intranet-core.Project_Manager#</td>
    <td>@im_render_user_id;noquote@</td>
  </tr>
  <tr> 
    <td>#intranet-core.Project_Type#</td>
    <td>@project_type;noquote@</td>
  </tr>
  <tr> 
    <td>#intranet-core.Project_Status#</td>
    <td>@project_status;noquote@</td>
  </tr>
  <if @show_start_date_p@ eq 1>
    <tr>
      <td>#intranet-core.Start_Date#</td>
      <td>@start_date_formatted;noquote@</td>
    </tr>
  </if>
  <if @show_end_date_p@ eq 1>
    <tr>
      <td>#intranet-core.Delivery_Date#</td>
      <td>@end_date_formatted;noquote@ @end_date_time;noquote@</td>
    </tr>
  </if>
  <tr>
    <td>#intranet-core.On_Track_Status#</td>
    <td>@im_project_on_track_bb;noquote@</td>
  </tr>
  <if @percent_completed@ not nil>
    <tr>
      <td>#intranet-core.Percent_Completed#</td>
      <td>@percent_completed_formatted;noquote@</td>
    </tr>
  </if>
  <if @view_budget_hours_p@ and @project_budget_hours@ not nil>
    <tr>
      <td>#intranet-core.Project_Budget_Hours#</td>
      <td>@project_budget_hours;noquote@</td>
    </tr>
  </if>  
  <if @view_budget_p@ and @project_budget@ not nil>
    <tr>
      <td>#intranet-core.Project_Budget#</td>
      <td>@project_budget;noquote@ @project_budget_currency;noquote@</td>
    </tr>
  </if>
  <if @company_project_nr@ not nil>
    <tr>
      <td>#intranet-core.Company_Project_Nr#</td>
      <td>@company_project_nr;noquote@</td>
    </tr>
  </if>
  <if @description@ not nil>
    <tr>
      <td>#intranet-core.Description#</td>
      <td width=250>@description;noquote@</td>
    </tr>
  </if>
  <if @project_dynfield_attribs:rowcount@ gt 0>
    <multiple name="project_dynfield_attribs">
      <if @project_dynfield_attribs.value@ not nil>
      <tr>
        <td>@project_dynfield_attribs.attrib_var;noquote@</td>
        <td>@project_dynfield_attribs.value;noquote@</td>
      </tr>
      </if>
    </multiple>
  </if>
  <if @write@ and @edit_project_base_data_p@>
    <tr> 
      <td>&nbsp; </td>
      <td> 
        <form action=/intranet/projects/new method=POST>
	  <input type="hidden" name="project_id" value="@project_id@">
	  <input type="hidden" name="return_url" value="@return_url@">
	  <input type=submit value="#intranet-core.Edit#" name=submit3>
        </form>
      </td>
    </tr>
  </if>
</table>
