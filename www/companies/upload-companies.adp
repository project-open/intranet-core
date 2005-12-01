<!-- packages/intranet-core/www/companies/new.adp -->
<!-- @author Juanjo Ruiz (juanjoruizx@yahoo.es) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="../master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">companies</property>

<form enctype="multipart/form-data" method=POST action="upload-companies-2.tcl">
<%= [export_form_vars return_url] %>
    <table border=0>
     <tr> 
	<td align=right>Filename</td>
	<td> 
	  <input type=file name=upload_file size=30>
	<%= [im_gif help "Use the &quot;Browse...&quot; button to locate your file, then click &quot;Open&quot;."] %>
	</td>
     </tr>
      <tr> 
	<td>Company Type</td>
	<td> 
	  <%= [im_company_type_select "company_type_id" 0] %>
	</td>
      </tr>
      <tr> 
	<td></td>
	<td> 
	  <input type=submit value="Submit and Upload">
	</td>
      </tr>
    </table>
</form>




<table border=0 cellspacing=0 cellpadding=1 width="70%">
<tr><td>

<h3>Import Companies From Microsoft Outlook 2000</h3>

<p>
This function is capable of importing a number of 
<span class=brandsec>&#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&#91;</span>
"Companies" from Microsoft Outlook 2000 (English). For other versions 
of Outlook please 
<A href="http://www.project-open.com/contact/">contact us</a>.
</p>

<p>
This function will look at the "Company" field of the Outlook contact 
and create a 
<span class=brandsec>&#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&#91;</span>
company with the same name. 
In addition, it will create a user from the rest of
the contact information and add this user as member of the company.
</p>

<p>
To test this functionality we recommend to follow the steps outlined
below, but with a "cut down" version of the CVS to only a few users.
Also, please test the functionality in a test server before using it
on you production system, because the import may overwrite existing
data and modifications.
</p>

<p>
In order to create a suitable CSV file for this function
please export your Outlook database:
</p>

<ul>
<li>Choose "File" / "Import and Export" from your Outlook
    menu and select "Export to a file".
<li>Choose the fomat "Comma Separated Values (Windows)"
<li>Choose the contacts folder to export. <br>
    Tip: You can create a special folder for the contacts
    that you want to integrate with Project/Open.
<li>Save the CSV file in any temporary directory
<li>Use the "Browse" button above to locate the CSV file
    and press "Submit".
<li>The system will show you a screen confirming the
    successful import of your contacts.
</ul>

We have included a sample document
<a href="/intranet/users/contacts.csv">here</a>.
Please note that Excel will not display this file correctly.
Also, Excel will render the file unusable if you save it 
from Excel. So please right-click the link and choose "Save
to Disk". And please don't blame us for Microsoft's internal 
incompatibilities... :-)

<h3>Duplicated Names</h3>

There are several differences between Outlook and Project/Open
that may lead to confusion or even loss of data in the worst
case:

<ul>
<li>
  Outlooks allows you to have multiple users with the same
  name, while Project/Open asumes that there is only one person 
  with a specific first and second name.<br>
  =&gt; Project/Open will overwrite the information of duplicate
  users.

<li>
  Outlook allows you to specify several email addresses for
  each user, while Project/Open requires exactly one email
  address.<br>
  =&gt; Project/Open will add the second and third email to the
  "notes" field of the user.  

</ul>


</td></tr>
</table>
