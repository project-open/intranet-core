<!-- packages/intranet/www/users/upload-users-2.adp -->
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="/packages/intranet-core/www/master">
<property name="title">@page_title@</property>

		<script type="text/javascript" charset="utf-8">
			function reset_import_and_database_selects() {
				/* 
				var i = document.getElementById("import_fields");	
				var db = document.getElementById("db_fields");
				i.selectedIndex="";
				db.selectedIndex="";
				*/
			}

			/* 
			$(function() {
				$("select#target").change(function(){
					$.getJSON("select.php",{id: $(this).val()}, function(j){
						var options = '';
						for (var i = 0; i < j.length; i++) {
							options += '<option value="' + j[i].optionValue + '">' + j[i].optionDisplay + '</option>';
						}
						$("#ctlPerson").html(options);
						$('#ctlPerson option:first').attr('selected', 'selected');
					})
				})			
			})
			*/

			function do_assign(){
			// reset selects 
	
				// Check if field is selected in both boxes
				if ( $('#import_fields').find(":selected").length == 0 ) {
					alert ('Please select value for Import column'); 
					return;	
				}; 
	
				if ( $('#db_fields').find(":selected").length == 0 ) {
					alert ('Please select value for DB column'); 
					return;	
				}; 

				// Check if option is already part of target box  
				var target_value = $('#import_fields').find(":selected").val() + '__' + $('#db_fields').find(":selected").val(); 
				$("#target option").each(function()
				{	
					if ( $(this).val() == target_value) {
						alert ('Assignment already exists');
						return;
					}
				});	
			
				// Add new option to 'target' select
				var add_target = '<option value="' + target_value + '" selected>' + $('#import_fields').find(":selected").text() + ' -> ' + $('#db_fields').find(":selected").text() + '</option>';
				$("#target").append(add_target);
					
				// remove options from import and db_field 
	 			$('#import_fields').find(":selected").remove();
	 			$('#db_fields').find(":selected").remove();
		};

		// reset fields 
		$(document).ready(function () {
			// Initialize 
			// reset_import_and_database_selects();
		});

		</script>


	<h1> <%=[lang::message::lookup "" intranet-core.MappingFieldsTitle "Step 2: Mapping columns \"Import File\" with \"Database Fields\""]%></h1>
	<%=[lang::message::lookup "" intranet-core.MappingFieldsExplain1 "Please choose one item each from Import File and User attributes and click 'Assign'<br>Once you are done click 'send'"]%>
	<%=[lang::message::lookup "" intranet-core.MappingFieldsExplain2 " Mapping of one of the following attributes is mandatory: user_id, email or First Names and Last Name"]%>
	<br><br>
	<form id='upload-users-2' action='upload-users-3' method="post">
		@hidden_fields;noquote@		
		<table cellpadding="0" cellspacing="0" border="0">
        	<tr>
	        <td>
		        <strong><%=[lang::message::lookup "" intranet-core.ColumnsImportFile "Import File"]%></strong><br><br>
			<select id="import_fields" size="25">
				<%=$select_options_import%>				
			</select>      
	        </td>
		<td>
			&nbsp;&nbsp;&nbsp;
		</td>
            	<td>
		        <strong><%=[lang::message::lookup "" intranet-core.ColumnsDb "User Attributes"]%></strong><br><br> 
			<select id="db_fields" size="25">
				<%=$select_options_db%>
			</select>            
            	</td>
		<td>
				<button onclick="do_assign(); return false;"><%=[lang::message::lookup "" intranet-core.Assign "Assign >>"]%></button>	
            	</td>
		<td>
			&nbsp;&nbsp;&nbsp;
		</td>
		<td>
			<strong><%=[lang::message::lookup "" intranet-core.Mapping "Mapping"]%></strong><br><br>
			<select multiple name="target" id="target" size="25" style="width:300px;"></select>
            	</td>
	        </tr>

		<tr>
		<td align="center" colspan="5">
		<br><br>
			<input type="submit" value="                              <%=[lang::message::lookup "" intranet-core.Submit "Submit"]%>                              ">
		</td>
		</tr>
        	</table>
	</form>

@notes_msg;noquote@