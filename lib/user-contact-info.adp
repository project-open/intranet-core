<if @result@ eq 1>
  <form method=POST action=contact-edit>
    <input type="hidden" name="user_id" value="@user_id;noquote@">
    <input type="hidden" name="return_url" value="@return_url;noquote@">
    <table cellpadding=0 cellspacing=2 border=0>
    <multiple name="user_columns">
    <if @user_columns.visible_p@ eq 1>
      <tr @user_columns.td_class;noquote@>
        <td>@user_columns.column_name;noquote@ &nbsp;</td>
        <td>@user_columns.column_render;noquote@</td>
      </tr>
    </if>
    </multiple>
    </table>
  </form>
</if>
<else>
  <form method=POST action=contact-edit>
    <input type="hidden" name="user_id" value="@user_id;noquote@>
    <input type="hidden" name="return_url" value="@return_url;noquote@">
    <table cellpadding=0 cellspacing=2 border=0>
      <tr><td colspan=2>#intranet-core.lt_No_contact_informatio#</td></tr>
      <if @write@ eq 1>
        <tr><td></td><td><input type="submit" value="#intranet-core.Edit#"></td></tr>
      </if>
    </table></form>
</else>