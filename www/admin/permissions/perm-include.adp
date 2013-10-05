<form action="@perm_modify_url@" method="post">
  @perm_form_export_vars;noquote@
  <p>
    <listtemplate name="permissions"></listtemplate>
  </p>
  <p>
    <input type="submit" value="Save changes">
  </p>
</form>

<if @mode@ eq datatable>
<script type="text/javascript">
		$(document).ready( function () {
		    var oTable = $('.jq-datatable').dataTable( {
        	"bJQueryUI": true,
			        "sScrollY": "1000px",
			        "sScrollX": "100%",
					"bScrollCollapse": true,
					"bPaginate": false,
					"bAutoWidth": true,
					"bFilter": false,
					"bPaginate": false,
					"bInfo": false
    		} );

		new FixedColumns( oTable );

		// ]po[ - band aids 
		$('.DTFC_LeftBodyWrapper').css("background-color", "white");
		$('.DTFC_LeftWrapper').css("height", $('.DTFC_LeftBodyWrapper').height()-10);

		} );
		
</script>
</if>
