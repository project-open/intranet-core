<master src="../master">
<property name="title">@page_title;noquote@</property>
<property name="admin_navbar_label">admin_home</property>

<!-- left - right - bottom  design -->

<table cellpadding=0 cellspacing=0 border=0 width=70%>
<tr>
  <td valign=top>

<H1>@page_title;noquote@</H1>

<p>
This functionality allows your to import the master data
from LTC-Organiser into 
<nobr><span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span></nobr>. This 
procedure only supports the Microsoft Access-based versions
of LTC-Organizer with recent versions.

<p>
This procedure can be executed by any Windows or Linux system 
administrator. However, non-technical persons might experience
difficulties. In this case please contact
<nobr><span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span></nobr>.
We can provide you installation services or telephone support.


<p>
You need to proceed with the following steps:

    <ol>

      <li>
        <b><A href=../backup/pg_dump>#intranet-core.PostgreSQL_Backup#</A></b>:<br>
	Please backup your current database contents before continuing
	with any of the following commands.<br>&nbsp;<br>

      <li>
        <b><A href="/intranet/admin/cleanup-demo/">Cleanup demo data</A></b>:<br>
	You need to remove any data from a demo system <i>before</i> 
	importing contents. Please make sure to delete any 
	previously existing users that might clash with the users
	to be imported.<br>&nbsp;<br>

      <li>
	<b>Import the LTC-Organiser database into PostgreSQL</A></b>:<br>
	Please use the "DBManager Professional Enterprise Edition"
	from <a href="http://www.dbtools.com.br/">DBTools Software</a>
	to load the Microsoft Access database of LTC-Organiser as
	a whole into the PostgreSQL database.
	The "professional" software is available as a 20 day trial 
	version for free.<br>
	To import the database please follow the steps:<br>&nbsp;<br>
	<ul>
	<li><b>Connect to your PostgreSQL database</b>:<br>
	    In the DBManager's Workspace click on the "Default Group" and then
	    on the 'Add a new Server" link on the right hand side. You will
	    get a dialoque where you have to add the information about
	    your PostgreSQL installation.<br>
	    The following sample values asume that you run DBManager
	    on the same computer where you run the Windows version of
	    <nobr><span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span></nobr>:<br>
<pre>
	Engine: PostgreSQL
	Server Name: projop@localhost
	Server Group: &lt;empty&gt;
	Hostname: localhost
	Port: 5432
	UserID: projop
	Password: &lt;empty&gt;
	Role: &lt;empty&gt;
	Database: projop
	Database Filename: &lt;empty&gt;
</pre>
	    Press "Test Connection" to check the connection.
	    <br>&nbsp;<br>
	
	<li><b>Import the Access Database into PostgreSQL</b>:<br>
	    The DBManager (only the Enterprise version) provides a 
	    "MSDAO Import Wizard" in the 
	    "Tools" - "Data Management" - "Wizard Manager" section 
	    that allows you to import the entire LTC-Organiser database
	    into PostgreSQL.
	    Please specify the Access database, "Select All" tables, 
	    use the standard
	    options for the import ("Import Data" and "Create Tables")
	    and use the standard table mapping (Source Table -&gt;
	    Target Table). Finally please select the existing "projop"
	    database as the target for the data import.<br>
	    After the import you should be able to see a number of
	    additional tables in the "projop" database, written with all 
	    capital letters such as "ACTION", "CONTACT", ...

	<li><b><a href="ltc-convert">Convert the LTC Data to 
	    <nobr><span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span></nobr></a></b>:<br>
	    
	</ul>


      <li><b>Comments</b>:<br>
	<ul>
	<li>Field Sizes:<br>
  LTC Organizer and ]project-open[ have different field
  sizes. This shouldt lead to issues with normal data,
  but exceptionally long fields may caus an error.

	<li>Countries:
  LTC Organizier allows the user to specified country
  names as a text field, while ]project-open[ requires 
  unique country_code.
  So spelling errors or non-English named countries will 
  lead to empty country fields in ]project-open[.
  

	<li>Contact_type:<br>
  1-User, 2-Provider, 3-Customer, 4-Other
  is converted into 1-Registered User, 2-Freelancer,
  3-Customer. These contact types are hard coded and 
  cant easily be changed.

	<li>Employees and Senior managers are not fully treated:<br>
  You need to add manually additional privileges to these
  user classes.

	<li>Skipped:<br>
  The following tables are not (yet) imported into ]po[:
<pre>
	- Translator_Details: Few entries
	- Translator_Software: Few entries
	- Trans_Soft: Defines the types of Software 
	  that a translator can install
	- Trans_Soft_Source & Trans_Soft_Target:
	  Source- and target language information for
	  Trans_Soft. May be used to describe automatic
	  translation software in more detail.
</pre>

    </ul>

  </td>
  <td valign=top>
    <%= [im_component_bay right] %>
  </td>
</tr>
</table><br>

<table cellpadding=0 cellspacing=0 border=0>
<tr><td>
  <%= [im_component_bay bottom] %>
</td></tr>
</table>


