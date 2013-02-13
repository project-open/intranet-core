<!-- packages/intranet-core/www/users/upload-users.adp -->
<master src="/packages/intranet-core/www/master">
<property name="title">@page_title@</property>

<h1><%=[lang::message::lookup "" intranet-core.TitleUploadUserData "Update User Data from CSV File"]%></h1>
<%=[lang::message::lookup "" intranet-core.TitleUploadUserDataExplain "Please upload your CSV file:"]%>

@page_body;noquote@

<%=[lang::message::lookup "" intranet-core.PleaseNote "Please Nnote"]%>:
<ul>
	<li><%=[lang::message::lookup "" intranet-core.HintUniqueId "Your file should contain at least one unique identifier. This could be either the \]po\[ User Id or the email address of the user"]%></li>
	<li><%=[lang::message::lookup "" intranet-core.NoUniqueId "If neither is provided, the system tries to map the values based on first name/last names"]%></li>
	<li><%=[lang::message::lookup "" intranet-core.NoUpdateIds "The following fields are used for identification only and will never be updated: user_id, username, first names, last name"]%></li>
	<li><%=[lang::message::lookup "" intranet-core.CurrencyToNumbers "Please avoid columns containing multiple elements, e.g. numbers with currency symbol."]%></li>
</ul>
