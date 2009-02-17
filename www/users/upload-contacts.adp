<!-- packages/intranet-core/www/companies/new.adp -->
<!-- @author Juanjo Ruiz (juanjoruizx@yahoo.es) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="../master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">user</property>


<if @reg_req_email_verify@ >
<h1>WARNING!!</h1>
<p>
Your system is configured in such a way that new users will 
receive an email message to ask them to verify their password.<br>
This means that all of the new users will receive emails.
This is probably not what you want.
</p>
<p>
Please go to Admin / Parameters and set "RegistrationRequiresEmailVerificationP"
to "0".
</p>
</if>



@page_body;noquote@

<table border=0 cellspacing=0 cellpadding=1 width="70%">
<tr><td>

<h3>Import From Microsoft Outlook 2000</h3>

<p>
This function is capable of importing "Contacts" from
Microsoft Outlook 2000 (English). For other versions of outlook
please
<A href="http://www.project-open.com/contact/">contact us</a>.
</p>
In order to create a suitable CSV file for this function
please export your Outlook database:

<ul>
<li>Choose "File" / "Import and Export" from your Outlook
    menu and select "Export to a file".
<li>Choose the fomat "Comma Separated Values (Windows)"
<li>Choose the contacts folder to export. <br>
    Tip: You can create a special folder for the contacts
    that you want to integrate with ]project-open[.
<li>Save the CSV file in any temporary directory
<li>Use the "Browse" button above to locate the CSV file
    and press "Submit".
<li>The system will show you a screen confirming the
    successful import of your contacts.
</ul>

We have included a sample document
<a href="/intranet/users/contacts.csv">here</a>.

<h3>Duplicated Names</h3>

There are several differences between Outlook and ]project-open[
that may lead to confusion or even loss of data in the worst
case:

<ul>
<li>
  Outlooks allows you to have multiple users with the same
  name, while ]project-open[ asumes that there is only one person
  with a specific first and second name.<br>
  =&gt; ]project-open[ will overwrite the information of duplicate
  users.

<li>
  Outlook allows you to specify several email addresses for
  each user, while ]project-open[ requires exactly one email
  address.<br>
  =&gt; ]project-open[ will add the second and third email to the
  "notes" field of the user.

</ul>


</td></tr>
</table>
