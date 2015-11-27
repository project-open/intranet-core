@warning;noquote@
<ul>
<multiple name="active_projects">
  <if @active_projects.llevel@ gt @active_projects.current_level@>
    <ul>
  </if>
  <if @active_projects.llevel@ lt @active_projects.current_level@>
    </ul>
  </if>  
    
  <li><a href="../projects/view?project_id=@active_projects.project_id@">@active_projects.project_nr@</a>: 
	@active_projects.project_name@ (@active_projects.project_status_name;noquote@)
</multiple>

<if @close_ul_p@>
    </ul>
</if>

<if @active_projects:rowcount@ eq 0>
  <li><i>#intranet-core.None#</i>
</if>

<if @ctr@ gt @max_projects@>
  <li><a href="/intranet/projects/index?company_id=@company_id@&amp;status_id=0">#intranet-core.more_projects#</a>
</if>
  
<if @admin@>
  <p><li><a href="../projects/new?company_id=@company_id@">#intranet-core.Add_a_project#</a>
</if>
</ul>






