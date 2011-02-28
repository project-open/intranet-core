

<table>
  <tr class=rowodd>
    <td>#intranet-core.Name#</td>
    <td>@company_name;noquote@</td>
  </tr>
  <tr class=roweven>
    <td>#intranet-core.Path#</td>
    <td>@company_path;noquote@</td>
  </tr>
  <tr class=rowodd>
    <td>#intranet-core.Status#</td>
    <td>@company_status;noquote@</td>
  </tr>
  <if @see_details@>
    <tr class=roweven>
      <td>#intranet-core.Client_Type#</td>
      <td>@company_type;noquote@</td>
    </tr>
    <tr class=rowodd>
      <td>#intranet-core.Key_Account#</td>
      <td><a href=@im_url_stub@/users/view?user_id=@manager_id@>@manager;noquote@</a></td>
    </tr>
    <tr class=rowodd>
      <td>#intranet-core.Phone#</td>
      <td>@phone;noquote@</td>
    </tr>
    <tr class=roweven>
      <td>#intranet-core.Fax#</td>
      <td>@fax;noquote@</td>
    </tr>
    <tr class=rowodd>
      <td>#intranet-core.Address1#</td>
      <td>@address_line1;noquote@</td>
    </tr>
    <tr class=roweven>
      <td>#intranet-core.Address2#</td>
      <td>@address_line2;noquote@</td>
    </tr>
    <tr class=rowodd>
      <td>#intranet-core.City#</td>
      <td>@address_city;noquote@</td>
    </tr>
   
    <if @some_american_readers_p@>
      <tr class=rowodd>
        <td>#intranet-core.State#</td>
        <td>@address_state;noquote@</td>
      </tr>
    </if>  

    <tr class=roweven>
      <td>#intranet-core.Postal_Code#</td>
      <td>@address_postal_code;noquote@</td>
    </tr>
    <tr class=rowodd>
      <td>#intranet-core.Country#</td>
      <td>@country_name;noquote@</td>
    </tr>
  </if>
  <if @site_concept@ not nil>
    <tr class=roweven>
      <td>#intranet-core.Web_Site#</td>
      <td><a href="@site_concept@">@site_concept;noquote@</a></td>
    </tr>
  </if>
  <tr class=rowodd>
    <td>#intranet-core.VAT_Number#</td>
    <td>@vat_number;noquote@</td>
  </tr>
  <tr class=roweven>
    <td>#intranet-core.Primary_contact#</td>
    <td>
      <if @primary_contact_id_p@ eq 0>
        <if @admin@>
          <a href="@primary_contact_url@">Add primary contact</a>
        </if>
        <else>
          <i>#intranet-core.none#</i>
        </else>  
      </if>
      <else>
        <a href=/intranet/users/view?user_id=@primary_contact_id@>@primary_contact_name;noquote@</a>
	<if @admin@>
	  (<a href="@primary_contact_url@">@im_gif_turn;noquote@</a> | 
	  <a href=@primary_contact_delete_url@">@im_gif_delete;noquote@</a>)
	</if>
      </else>
    </td>
  </tr>

  
  <tr class=rowodd>
    <td>#intranet-core.Accounting_contact#</td>
    <td>
      <if @accounting_contact_id_p@ eq 0>
        <if @admin@>
	  <a href=@accounting_contact_url@>#intranet-core.lt_Add_accounting_contac#</a>
	</if>
	<else>
	  <i>#intranet-core.none#</i>
	</else>
      </if>
      <else>
        <a href=/intranet/users/view?user_id=@accounting_contact_id@>@accounting_contact_name;noquote@</a>
	<if @admin@>
	    (<a href="@accounting_contact_url@">@im_gif_turn;noquote@</a> 
	    | <a href="@accounting_delete_url@">@im_gif_delete;noquote@</a>) 
	</if>
     </else>
    </td>
  </tr>

  <tr class="roweven">
    <td>#intranet-core.Start_Date#</td>
    <td>@start_date;noquote@</td>
  </tr>

  <if @note_p@>
    <tr @bgcolor@>
      <td>#intranet-core.Notes#</td>
      <td><font size=-1>@note;noquote@</font></td>
    </tr>
  </if>
 

 
  <multiple name="company_dynfield_attribs">
    <if @company_dynfield_attribs.value_p@>	
      <tr @company_dynfield_attribs.bgcolor@>
        <td>@company_dynfield_attribs.attrib_name;noquote@</td>
	<td>@company_dynfield_attribs.value;noquote@</td>
      </tr>  
    </if>
  </multiple>

  <if @admin@>
    <tr>
      <td>&nbsp;</td>
      <td>
        <form action=new method=POST>
	  <input type="hidden" name="company_id" value="@company_id@">
	  <input type="hidden" name="return_url" value="@return_url@">
          <input type="submit" value="#intranet-core.Edit#">
        </form>
      </td>
    </tr>
  </if>
</table>
