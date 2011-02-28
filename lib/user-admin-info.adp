<table cellpadding=0 cellspacing=2 border=0>
  <tr>
    <td>
      <ul>
        <if @last_visit@ not nil>
          <li>#intranet-core.Last_visit#: @last_visit;noquote@</li>
	</if>
	<if @registration_ip@ not nil>
	  <li>
	    #intranet-core.lt_Registered_from_regis# by <a href=/intranet/users/view?user_id=@creation_user_id;noquote@>@creation_user_name;noquote@</a>
	  </li>
	</if>
	<if @admin@ eq 1>
	  <li>#intranet-core.lt_Member_state_user_sta#</li>
	</if>
	<else>
	  <li>#intranet-core.User_state#: @user_state;noquote@</li>
	</else>

	<if @admin@ eq 1 or  @user_id@ eq @current_user_id@> 
	  <li><a href=@change_pwd_url@>#intranet-core.lt_Update_this_users_pas#</a></li>
	</if>
	<if @otp_installed_p@>
	  <li><a href=@list_otp_pwd_url@>#intranet-otp.Print_OTP_list#</a><li>
	</if>
	<if @admin@ and @add_companies_p@>
          <li><a href=@new_company_from_user_url@>#intranet-core.Create_New_Company_for_User#</a></li>
	</if>
	<if @admin@ eq 1>
	  <li><a href=become?user_id=@user_id_from_search@>#intranet-core.Become_this_user#</a></li>
	</if>
	<li>#intranet-core.Created#: @date_created;noquote@</li>
      </ul>
    </td>
  </tr>
</table>