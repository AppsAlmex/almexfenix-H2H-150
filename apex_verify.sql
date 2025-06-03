-- Oracle APEX Diagnostic Agent for APEX Installs
-- =====================================================

-- USAGE:
-- ======
-- Login to SQL*PLUS as the SYSTEM user and then execute this SQL script
-- as follows:
--  @<path>/apex_verify.sql
-- By default output is written to apex_verify_out.html in the current directory 

REM The formatting method used in this note is based on the formatting methods used in the following notes:
REM Oracle9iAS Portal Diagnostics Agent (PDA) (Doc ID 169490.1)
REM Capture Single Sign-On Configuration Tables to HTML Formatted File (Doc ID 244112.1)


clear buffer;

set serveroutput on
set echo off
set arraysize 1
set trims on
set linesize 240
set pagesize 0
-- set sqlprefix off
set verify off
set feedback off
set heading off
set timing off
set define on
set escape off

--prompt V 3.6 - Modified July 20, 2019 query to show status of APEX and ORDS related accounts. 
--prompt
--prompt Enter output filename.  If file exists will be overwritten.
spool apex_verify_out.html
exec dbms_output.put_line('<!DOCTYPE html>');
exec dbms_output.put_line('<html>');
select '<head><title>APEX Verification Script</title></head><body bgcolor="#fdfdfd">' from dual;
select '<body><div align=left><b><font face="Arial,Helvetica"><font color="#ff0000">' ||
       '<font size=-2>' || to_char(sysdate, 'DD-MON-YYYY HH24:MI:SS') || ' Ver 3.6 ' ||
       '</font></font></font></b></div></body>' from dual;

--START Active version of APEX in the DB
define APEX = 'APEX IS NOT INSTALLED'
column APEX_VER new_val APEX NOPRINT

--use the following to get the apex schema for the version of apex registered in the dba_registry.
SELECT SCHEMA APEX_VER
FROM dba_registry
WHERE comp_id = 'APEX'; 
--WHERE (comp_id = 'APEX' or comp_id like 'HTML%');


define GET_VER ='APEX_RELEASE';
define VERSION = '&APEX..&GET_VER';

--Above notionally resolves to APEX_040200.APEX_RELEASE
--END determine Active version of APEX in the DB


--START Determine tablespace used by APEX schema
define APEX_TABLESPACE = 'NO TABLESPACE'
column APEX_TAB new_val APEX_TABLESPACE NOPRINT
select default_tablespace APEX_TAB from dba_users where username='&APEX';
--END Determine tablespace used by APEX schema

--START Determine IF tablespace used by APEX schema is autoextend or not
define APEX_TABLESPACE_AUTOEXTEND = 'NO'
column APEX_TAB_AE new_val APEX_TABLESPACE_AUTOEXTEND NOPRINT
select distinct(autoextensible)APEX_TAB_AE from dba_data_files where tablespace_name = '&APEX_TABLESPACE';
--END Determine IF tablespace used by APEX schema is autoextend or not

--START Determine tablespace used by FLOWS_FILES
define FLOWS_FILES_TABLESPACE = 'NO TABLESPACE'
column FLOWS_FILES_TAB new_val FLOWS_FILES_TABLESPACE NOPRINT
select default_tablespace FLOWS_FILES_TAB from dba_users where username='FLOWS_FILES';
--END Determine tablespace used by FLOWS_FILES

--START Determine IF tablespace used by FLOWS_FILES schema is autoextend or not
define FLOWS_FILES_TABLESPACE_AUTO = 'NO'
column FLOWS_FILES_TAB_AE new_val FLOWS_FILES_TABLESPACE_AUTO NOPRINT
select distinct(autoextensible)FLOWS_FILES_TAB_AE from dba_data_files where tablespace_name = '&FLOWS_FILES_TABLESPACE';
--END Determine IF tablespace used by FLOWS_FILES schema is autoetxend or not

--START Determine temporary tablespace used by APEX Installation
define TEMP_APEX = 'NO TABLESPACE'
column APEX_TEMP new_val TEMP_APEX NOPRINT
select temporary_tablespace APEX_TEMP from dba_users where username='&APEX';
--END Determine temporary tablespace used by APEX Installation

--START  DATABASE VERSION
-- select banner from v$version;
select '<h5><font face="VERDANA"><font color="#000000">APEX Database Information' ||
       '<font size=-2></font></font></font></h5>' FROM dual;
select '<TABLE BORDER  CELLPADDING=2>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' || 'DB Information </FONT></B></TH>' FROM dual;
select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || banner ||
       '</FONT></TD></TR>' from v$version;
select '</TABLE>' FROM dual;
--COMMENTS
--select '<body><i><font face="Arial,Helvetica"><font color="#FF0000"><font size=3> For APEX 3.2 and below, DB must be 9.2.0.3 or above.<BR>
exec dbms_output.put_line('<body><font face="Arial,Helvetica"><font color="#FF0000"><font size=3><BR>For APEX 3.2 and below, DB must be 9.2.0.3 or above.<BR>For APEX 4.0, DB must be 10.2.0.3 or above or 10g Express<BR>For APEX 5.0, DB must be 11.1.0.7 or later including Enterprise Edition and Express Edition (Oracle Database XE)<BR>For APEX 5.1 and 18.1, DB must be 11.2.0.4 or later including Enterprise Edition and Express Edition (Oracle Database XE)</font></font></font></body>');

 
--END DATABASE VERSION

--start Get exact version of APEX
select '<h5><font face="VERDANA"><font color="#000000">APEX ' ||
       'Version Registered in DBA Registry <font size=-2></font></font></font></h5>' FROM dual;
select '<TABLE BORDER  CELLPADDING=2>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' ||
       'Version </FONT></B></TH>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' ||
       'API Compatibility</FONT></B></TH>' FROM dual;
select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2>' || version_no ||
       '</FONT></TD>', '<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2>' ||
       api_compatibility || '</FONT></TD></TR>' from &VERSION; 
select '</TABLE>' FROM dual;
--end --Get exact version of APEX

--Begin Get Number of Valids in the APEX Schema
select '<h5><font face="VERDANA"><font color="#000000"> Number of APEX Valids/Invalids in the &APEX and FLOWS_FILES schemas <font size=-2></font></font></font></h5>'
   FROM dual;
select '<TABLE BORDER  CELLPADDING=2>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>Total APEX Valids </FONT></B></TH>' FROM dual;
select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || count(1) || '</FONT></TD></TR>'
from dba_objects
where owner = upper('&APEX') and status='VALID';
select '</TABLE>' FROM dual;

--End Get Number of Valids in the APEX Schema

--Begin Get number of Invalids in the APEX Schema
select '<TABLE BORDER  CELLPADDING=2>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>Total APEX Invalids </FONT></B></TH>' FROM dual;
select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || count(1) || '</FONT></TD></TR>'
from dba_objects
where owner  = upper('&APEX') and status='INVALID';
select '</TABLE>' FROM dual;
--End Get Number of invalids in the APEX Schema

--Begin Get Number of Invalids in the flows_files schema

select '<TABLE BORDER  CELLPADDING=2>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>Total FLOWS_FILES Invalids </FONT></B></TH>' FROM dual;
select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || count(1) || '</FONT></TD></TR>'  from dba_objects
where owner  = 'FLOWS_FILES' and status='INVALID';
select '</TABLE>' FROM dual;

--End Get Number of Invalids in the flows_files schema


--BEGIN Get information about Valids/Invalids in the APEX Schema
select '<h5><font face="VERDANA"><font color="#000000"> List of &APEX and FLOWS_FILES Invalid Objects <font size=-2></font></font></font></h5>'
   FROM dual;
select '<TABLE BORDER  CELLPADDING=2>' FROM dual;

select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' ||
       'Object Name</FONT></B></TH>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' ||
       'Object Type</FONT></B></TH>' FROM dual;
select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || Object_name || '</FONT></TD>',
           '<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || object_type || '</FONT></TD></TR>'
from dba_objects where owner in (UPPER('&APEX'),'FLOWS_FILES')  and status = 'INVALID' order by object_type;
select '</TABLE>' FROM dual;
--End Get information about Valids/Invalids in the APEX Schema

--Start Get images directory

exec dbms_output.put_line( '<h5><font face="VERDANA"><font color="#000000"> Virtual Image Directory (default and recommended -> /i/)<font size=-2></font></font></font></h5>' );
exec dbms_output.put_line( '<TABLE BORDER  CELLPADDING=2>' );
exec dbms_output.put_line( '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2> Virtual Directory </FONT></B></TH>' );

exec dbms_output.put_line( '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> '||&APEX..wwv_flow_image_prefix.g_image_prefix  ||  '</FONT></TD></TR>');
--select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || flow_image_prefix ||  '</FONT></TD></TR>' from &APEX..wwv_flows where security_group_id = 10 and rownum=1;
exec dbms_output.put_line( '</TABLE>' );
--End Get images directory

--START APEX Related Schemas and status
exec dbms_output.put_line(  '<h5><font face="VERDANA"><font color="#000000">APEX Related Schemas ' || ' <font size=-2></font></font></font></h5>');
exec dbms_output.put_line('<TABLE BORDER  CELLPADDING=2>');
exec dbms_output.put_line( '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' || 'APEX Related Schemas </B></FONT></TH>');
exec dbms_output.put_line( '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' || 'Account Status </B></FONT></TH>');

select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || username ||'</FONT></TD>',
           '<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || account_status || '</FONT></TD></TR>'
from dba_users
where (username like 'APEX%' or username = 'FLOWS_FILES') and
username not in (select  username from dba_users where (username like 'APEX\_0%' escape '\' or username like 'FLOWS\_0%' escape '\') and (username <> '&APEX'))order by username asc;

exec dbms_output.put_line('</TABLE>');

-- END APEX Related Schemas

--START ORDS Related Schemas
exec dbms_output.put_line( '<h5><font face="VERDANA"><font color="#000000">ORDS Related Schemas ' ||' <font size=-2></font></font></font></h5>');
exec dbms_output.put_line('<TABLE BORDER  CELLPADDING=2>');

exec dbms_output.put_line( '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' || 'ORDS Related Schemas </B></FONT></TH>');
exec dbms_output.put_line( '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' || 'Account Status </B></FONT></TH>');

select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || username ||'</FONT></TD>',
           '<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || account_status || '</FONT></TD></TR>'
from dba_users
where username in ('ORDS_PUBLIC_USER','ORDS_METADATA');
exec dbms_output.put_line('</TABLE>');

-- END ORDS Related Schemas
--START Proxy Users
select '<h5><font face="VERDANA"><font color="#000000">Proxy Users' ||
       ' <font size=-2></font></font></font></h5>' FROM dual;
select '<TABLE BORDER  CELLPADDING=2>' FROM dual;

select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' || 'Proxy</B></FONT></TH>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' || 'Client</FONT></B></TH>' FROM dual;

select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || proxy || '</FONT></TD>',
           '<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || client || '</FONT></TD>'
  from proxy_users
 where proxy in ( 'APEX_REST_PUBLIC_USER', 'ORDS_PUBLIC_USER','ORDS_REST_PUBLIC_USER' )
 order by proxy, client;
        
select '</TABLE>' FROM dual;
-- END Proxy Users

--Start ORDS Version
exec dbms_output.put_line( '<h5><font face="VERDANA"><font color="#000000"> ORDS Version<font size=-2></font></font></font></h5>' );
select '<TABLE BORDER  CELLPADDING=2>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' || 'ORDS Version </B></FONT></TH>' FROM dual;
select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || version  ||  '</FONT></TD></TR>' from ords_metadata.ords_version;
select '</TABLE>' FROM dual;

--End ORDS Version


--START Prior APEX Versions which May be Cleaned Up
exec dbms_output.put_line('<h5><font face="VERDANA"><font color="#000000">Prior APEX Versions which May be Cleaned Up<font size=-2></font></font></font></h5>');
exec dbms_output.put_line('<TABLE BORDER  CELLPADDING=2>');
exec dbms_output.put_line('<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>Consider Removing All Listed </B></FONT></TH>');

select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || username ||'</FONT></TD></TR>' 
       from dba_users where (username like 'APEX\_0%' escape '\' or username like 'FLOWS\_0%' escape '\') and (username <> '&APEX') order by username asc;
exec dbms_output.put_line('</TABLE>');
--Comment on APEX Version Cleanup
select '<body><font face="Arial,Helvetica"><font color="#FF0000">' ||
       '<font size=3>If your current APEX version is fully functional and backed up, consider removing earlier versions.<BR>
Generally, this involves dropping the schema for the previous version or versions.  See the installation guide section entitled "About Removing Prior Oracle Application Express Installations" for more information.</font></font></font></body>'
   from dual;
--END Prior APEX Versions which May be Cleaned Up

--START APEX_PUBLIC_USER and ANONYMOUS Account Info

select '<h5><font face="VERDANA"><font color="#000000">' ||'APEX Account Related Info <font size=-2></font></font></font></h5>'
   FROM dual;
select '<TABLE BORDER  CELLPADDING=2>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' ||'Username</FONT></B></TH>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' ||'Account Status</FONT></B></TH>' FROM dual;

col username format a22
col account_status format a25
select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || username ||'</FONT></TD>',
           '<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || account_status || '</FONT></TD>'
       from dba_users where username in('APEX_PUBLIC_USER','ANONYMOUS');
 select '</TABLE>' FROM dual;

--END APEX_PUBLIC_USER and ANONYMOUS Account Info

--START APEX Instance Administrator Account Info

exec dbms_output.put_line('<h5><font face="VERDANA"><font color="#000000">APEX Instance Administrator Account Info<font size=-2></font></font></font></h5>');
exec dbms_output.put_line('<TABLE BORDER  CELLPADDING=2>');
exec dbms_output.put_line('<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>Username</FONT></B></TH>');
exec dbms_output.put_line('<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>Workspace Name</FONT></B></TH>');
exec dbms_output.put_line('<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>Workspace ID</FONT></B></TH>');
exec dbms_output.put_line('<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>Account Locked?</FONT></B></TH>');

col user_name format a8
col  workspace_name format a25
col  workspace_id format 999
col account_locked format a1
select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || user_name ||'</FONT></TD>',
            '<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' ||workspace_name || '</FONT></TD>',
            '<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' ||workspace_id|| '</FONT></TD>',
            '<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || account_locked ||'</FONT></TD></TR>'
FROM APEX_WORKSPACE_APEX_USERS WHERE WORKSPACE_NAME = 'INTERNAL';
exec dbms_output.put_line('</TABLE>');


--END APEX Instance Administrator Account Info



--START PL/SQL TOOLKIT VERSION
-- select owa_util.get_version from dual;
select '<h5><font face="VERDANA"><font color="#000000">PL/SQL Toolkit Version <font size=-2></font></font></font></h5>' FROM dual;
select '<TABLE BORDER  CELLPADDING=2>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' || 'Version </B></FONT></TH>' FROM dual;
select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || owa_util.get_version  ||  '</FONT></TD></TR>' from dual;
select '</TABLE>' FROM dual;
-- COMMENTS
select '<body><font face="Arial,Helvetica"><font color="#FF0000">' ||
       '<font size=3>Check the PL/SQL Web Toolkit version. If less than 10.1.2.0.6 then ' ||
       'upgrade (discuss with Oracle Support before upgrading)</font></font>' ||
       '</font></body>' from dual;
--END PL/SQL TOOLKIT VERSION

--start DUPLICATE OWA PACKAGES 
-- SELECT OWNER, OBJECT_TYPE FROM DBA_OBJECTS WHERE OBJECT_NAME = 'OWA';
select '<h5><font face="VERDANA"><font color="#000000">Duplicate OWA ' ||
       'packages <font size=-2></font></font></font></h5>' FROM dual;
select '<TABLE BORDER  CELLPADDING=2>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' || 'Owner</B></FONT></TH>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' || 'Object Type</FONT></B></TH>' FROM dual;
select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || owner ||'</FONT></TD>',
           '<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || object_type || '</FONT></TD></TR>'
          FROM DBA_OBJECTS WHERE OBJECT_NAME = 'OWA';
select '</TABLE>' FROM dual;
-- COMMENTS

select '<body><font face="Arial,Helvetica"><font color="#FF0000">' ||
       '<font size=3>Make sure you do not have duplicate copies of OWA packages. You should see the output as below:<BR><BR>
        SYS..............PACKAGE<BR>
        SYS..............PACKAGE BODY<BR>
        PUBLIC........SYNONYM</font></font></font></body>'
   from dual;
--end DUPLICATE OWA PACKAGES 

--START Shared Pool Size
select '<h5><font face="VERDANA"><font color="#000000">Shared Pool Size - Please see the APEX Installation Guide for your APEX/DB version for required settings ' ||
       ' <font size=-2></font></font></font></h5>' FROM dual;
select '<TABLE BORDER  CELLPADDING=2>' FROM dual;

select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>Shared Pool Size (MB)</FONT></B></TH>'
 FROM dual;
select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' ||value/1024/1024|| '</FONT></TD></TR>'
from v$parameter where name = 'shared_pool_size';
select '</TABLE>' FROM dual;

--END Shared Pool Size

--START NLS Characterset Values

select '<h5><font face="VERDANA"><font color="#000000">NLS CHARACTER SET Information<font size=-2></font></font></font></h5>'
 FROM dual;
select '<TABLE BORDER  CELLPADDING=2>' FROM dual;

select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>Parameter</FONT></B></TH>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>Parameter Value</FONT></B></TH>' FROM dual;


select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || parameter ||'</FONT></TD>',
           '<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || value     ||'</FONT></TD></TR>'
   from NLS_DATABASE_PARAMETERS where parameter in ('NLS_CHARACTERSET','NLS_NCHAR_CHARACTERSET');

select '</TABLE>' FROM dual;

--END - NLS Characterset Values

--START Free Space in System 


select '<h5><font face="VERDANA"><font color="#000000">Free Space in System Tablespace ' ||
       ' <font size=-2></font></font></font></h5>' FROM dual;
select '<TABLE BORDER  CELLPADDING=2>' FROM dual;

select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>MB Free in System </FONT></B></TH>'
 FROM dual;
select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' ||sum(bytes)/1024/1024|| '</FONT></TD></TR>'
from dba_free_space
where tablespace_name ='SYSTEM';
select '</TABLE>' FROM dual;

--END  Free Space in System Tablespace


--START Free Space in APEX Tablespace

select '<h5><font face="VERDANA"><font color="#000000">Free Space in &APEX_TABLESPACE Tablespace (AUTOEXTEND=&APEX_TABLESPACE_AUTOEXTEND) used by &APEX<font size=-2></font></font></font></h5>'
FROM dual;
select '<TABLE BORDER  CELLPADDING=2>' FROM dual;

select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>Free Space in MB</FONT></B></TH>'
 FROM dual;
select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' ||sum(bytes)/1024/1024|| '</FONT></TD></TR>'
from dba_free_space
where tablespace_name ='&APEX_TABLESPACE';
select '</TABLE>' FROM dual;

--END   Free Space in APEX Tablespace

--START Free Space in FLOWS_FILES Tablespace

select '<h5><font face="VERDANA"><font color="#000000">Free Space in &FLOWS_FILES_TABLESPACE (AUTOEXTEND=&FLOWS_FILES_TABLESPACE_AUTO) Tablespace used by FLOWS_FILES<font size=-2></font></font></font></h5>'
FROM dual;
select '<TABLE BORDER  CELLPADDING=2>' FROM dual;

select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>Free Space in MB</FONT></B></TH>'
 FROM dual;
select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' ||sum(bytes)/1024/1024|| '</FONT></TD></TR>'
from dba_free_space
where tablespace_name ='&FLOWS_FILES_TABLESPACE';
select '</TABLE>' FROM dual;

--END   Free Space in FLOWS_FILES Tablespace

--START  Temporary Tablespace used by the APEX Installation (By default the APEX Schema and FLOWS_FILES use same temporary tablespace during installation)

select '<h5><font face="VERDANA"><font color="#000000">Default Temporary Tablespace used for &APEX is: &TEMP_APEX<font size=-2></font></font></font></h5>'
FROM dual;
--select '<TABLE BORDER  CELLPADDING=2>' FROM dual;

--END   Temporary Tablespace used by the APEX Installation (By default the APEX Schema and FLOWS_FILES use same temporary tablespace during installation)


-- Begin Get Job Queue Processes

select '<h5><font face="VERDANA"><font color="#000000"> Number of Job Queue Processes<font size=-2></font></font></font></h5>' FROM dual;
select '<TABLE BORDER  CELLPADDING=2>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2> Number of Job Queue Processes</FONT></B></TH>' FROM dual;
select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || value  ||  '</FONT></TD></TR>' from v$parameter where name='job_queue_processes';
select '</TABLE>' FROM dual;


-- End Get Job Queue Processes 


--Start Get information about XML DB

select '<h5><font face="VERDANA"><font color="#000000">' ||
       'XDB STATUS <font size=-2></font></font></font></h5>'
   FROM dual;
select '<TABLE BORDER  CELLPADDING=2>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' ||
       'owner</FONT></B></TH>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' ||
       'object_name</FONT></B></TH>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' ||
       'object_type</FONT></B></TH>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' ||
       'Status</FONT></B></TH>' FROM dual;

col owner format a10
col object_name format a20
select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || owner       ||'</FONT></TD>',
           '<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || object_name || '</FONT></TD>',
           '<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || object_type || '</FONT></TD>',
           '<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' ||      status || '</FONT></TD></TR>'
       from dba_objects where object_name = 'DBMS_XMLPARSER';
select '</TABLE>' FROM dual;
select '<body><font face="Arial,Helvetica"><font color="#FF0000">' ||
       '<font size=3>Make sure XML DB packages are installed and valid.  You should see the output as below:<BR><BR>
         PUBLIC....DBMS_XMLPARSER....SYNONYM..............VALID<BR>
         XDB..........DBMS_XMLPARSER....PACKAGE...............VALID<BR>
         XDB..........DBMS_XMLPARSER....PACKAGE BODY....VALID</font></font></font></body>'
from dual;

--END Get information about XML DB

--Start Determine if APEX is a Development or Runtime Installation
define WWV_FLOWS = 'WWV_FLOWS'
define INSTALL_TYPE = '&APEX..&WWV_FLOWS'

select '<h5><font face="VERDANA"><font color="#000000">' ||
       'APEX Install Type (1=Dev 0=Runtime) <font size=-2></font></font></font></h5>'
   FROM dual;
select '<TABLE BORDER  CELLPADDING=2>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' ||'Install Type</FONT></B></TH>' FROM dual;
select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || count(1)  ||
       '</FONT></TD></TR>' from &INSTALL_TYPE where id = 4000;
select '</TABLE>' FROM dual;
--End Determine if APEX is a Development or Runtime Installation


--BEGIN Determine if APEX has ever been used
exec dbms_output.put_line('<h5><font face="VERDANA"><font color="#000000">Has APEX Been Used? <font size=-2></font></font></font></h5>');
exec dbms_output.put_line('<TABLE BORDER  CELLPADDING=2>');
exec dbms_output.put_line('<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>Workspace ID</FONT></B></TH>');
exec dbms_output.put_line('<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>Workspace Name</FONT></B></TH>');
select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || workspace_id  ||'</FONT></TD>',
            '<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || workspace_display_name || '</FONT></TD></TR>'
from apex_workspaces order by workspace_id;
exec dbms_output.put_line('</TABLE>');
--Comment on usage 
select '<body><font face="Arial,Helvetica"><font color="#FF0000">' ||
       '<font size=3>Internal Workspaces have IDs less than 100,000.<BR>
        Any Workspace ID >= 100,000 indicates APEX has been used. (In 12c Multi-Tenant, check only valid for PDB).</font></font></font></body>'
   from dual;
--END   Determine if APEX has ever been used


--Start Determine DB Service Name

select '<h5><font face="VERDANA"><font color="#000000">' ||
       'Database Service Name <font size=-2></font></font></font></h5>'
   FROM dual;
select '<TABLE BORDER  CELLPADDING=2>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' ||
       'DB Service Name</FONT></B></TH>' FROM dual;
select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || value  ||
       '</FONT></TD></TR>' from v$parameter where name='service_names';
select '</TABLE>' FROM dual;

exec dbms_output.put_line('<body><font face="Arial,Helvetica"><font color="#FF0000"><font size=3><BR>If in a 12c multi-tenant environment, the above is the service name of the CDB.<BR>This query will show the service name of the PDB:<BR> select name, pdb from cdb_services;</font></font></font></body>');

--End  Determine DB Service Name

--Start Determine DB SID

exec dbms_output.put_line('<h5><font face="VERDANA"><font color="#000000">Database SID <font size=-2></font></font></font></h5>');
   
exec dbms_output.put_line('<TABLE BORDER  CELLPADDING=2>');
exec dbms_output.put_line('<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>DB SID</FONT></B></TH>');
select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> '|| instance|| '</FONT></TD></TR>' from v$thread;
exec dbms_output.put_line('</TABLE>');

--End  Determine DB Sid



--START check for enabling of Network Services
select '<h5><font face="VERDANA"><font color="#000000">' ||
       'Enabling of Network Services (11g DBs and Later) <font size=-2></font></font></font></h5>'
   FROM dual;
select '<TABLE BORDER  CELLPADDING=2>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' ||
       'ACL</FONT></B></TH>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' ||
       'Principal</FONT></B></TH>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' ||
       'Privilege</FONT></B></TH>' FROM dual;
select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || acl ||
       '</FONT></TD>', '<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' ||
       principal || '</FONT></TD>','<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' ||
       privilege || '</FONT></TD></TR>'
       from dba_network_acl_privileges;
select '</TABLE>' FROM dual;
--END check for enabling of network services

--START Get DBA Registry Info

select '<h5><font face="VERDANA"><font color="#000000">' ||'DBA Registry Info <font size=-2></font></font></font></h5>'
   FROM dual;
select '<TABLE BORDER  CELLPADDING=2>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' ||'Component ID</FONT></B></TH>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' ||
       'Component Name</FONT></B></TH>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' ||
       'Version</FONT></B></TH>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' ||
       'Schema</FONT></B></TH>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' ||
       'Status</FONT></B></TH>' FROM dual;

col comp_name format a30
col version format a10
col status format a10
col comp_id format a15

select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || comp_id ||'</FONT></TD>',
           '<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || comp_name || '</FONT></TD>',
           '<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || version || '</FONT></TD>',
           '<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || schema || '</FONT></TD>',
           '<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || status || '</FONT></TD></TR>'
       from dba_registry order by comp_id;
select '</TABLE>' FROM dual;

--END Get DBA Registry Info

--START Get APEX Instance Settings

exec dbms_output.put_line( '<h5><font face="VERDANA"><font color="#000000">'||' APEX Instance Settings <font size=-2></font></font></font></h5>' );

exec dbms_output.put_line('<TABLE BORDER  CELLPADDING=2>');
exec dbms_output.put_line('<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' ||'Name</FONT></B></TH>');
exec dbms_output.put_line('<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' ||'Value</FONT></B></TH>');
exec dbms_output.put_line('<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' ||'Description</FONT></B></TH>');

select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' ||Name||'</FONT></TD>',
           '<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' ||Value || '</FONT></TD>',
           '<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' ||pref_desc|| '</FONT></TD></TR>'
from &APEX..wwv_flow_platform_prefs order by name;
-- where NAME in('AUTOEXTEND_TABLESPACES','BIGFILE_TABLESPACES_ENABLED','PRINT_BIB_LICENSED','PRINT_SVR_PROTOCOL','PRINT_SVR_HOST','PRINT_SVR_PORT','SMTP_HOST_ADDRESS','SMTP_HOST_PORT') order by name;
           --from &APEX..wwv_flow_platform_prefs order by name;
exec dbms_output.put_line('</TABLE>');


--END   Get APEX Instance Settings

--START  Show the number of objects granted to the APEX schema
exec dbms_output.put_line( '<h5><font face="VERDANA"><font color="#000000">'||' APEX Instance Grant Information. (Note that grant details may vary between APEX versions).<font size=-2></font></font></font></h5>' );
exec dbms_output.put_line('<h5><font face="VERDANA"><font color="#33ccff"> <font size=-2></font></font></font></h5>');
exec dbms_output.put_line('<TABLE BORDER  CELLPADDING=2>');
exec dbms_output.put_line('<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>Total Objects Granted to &APEX</FONT></B></TH>');
select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || count(1) ||'</FONT></TD></TR>'
from dba_tab_privs where grantee = '&APEX';
exec dbms_output.put_line('</TABLE>');
--END

--Start Get Grants given to APEX Schema

exec dbms_output.put_line('<h5><font face="VERDANA"><font color="#000000">The following displays all grants issued to the &APEX Schema.<font size=-2></font></font></font></h5>');
exec dbms_output.put_line('<TABLE BORDER  CELLPADDING=2>');
exec dbms_output.put_line('<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>Table Name</FONT></B></TH>');
exec dbms_output.put_line('<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>Privilege</FONT></B></TH>');

select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || table_name || '</FONT></TD>',
           '<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || privilege || '</FONT></TD></TR>'
from dba_tab_privs where grantee = '&APEX'
order by table_name;

exec dbms_output.put_line('</TABLE>');
--END

--START TOTAL INVALID OBJECTS

select '<h5><font face="VERDANA"><font color="#000000">' ||
       'Number of Invalid Objects in the DB <font size=-2></font></font></font></h5>'
   FROM dual;

select '<TABLE BORDER  CELLPADDING=2>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' ||
       'Total Invalid Objects in DB</FONT></B></TH>' FROM dual;
select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || count(1) ||
       '</FONT></TD></TR>' from dba_objects where status = 'INVALID';
select '</TABLE>' FROM dual;
-- COMMENTS
select '<body><font face="Arial,Helvetica"><font color="#FF0000">' ||
       '<font size=3>There should be no invalid objects in the database ' ||
       'pertaining to the owners within APEX/FLOWS. If there ' ||
       'are any, recompile. Use the <b>utlrp.sql</b> script under the ' ||
       'database home to recompile.</font></font></font></body>' from dual;
--end TOTAL INVALID OBJECTS


--START LIST OF ALL INVALID OBJECTS IN THE DATABASE
select '<h5><font face="VERDANA"><font color="#000000">' ||
       'List of ALL Invalid Objects in the DB <font size=-2></font></font></font></h5>'
   FROM dual;
select '<TABLE BORDER  CELLPADDING=2>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>Owner</FONT></B></TH>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>Object Name</FONT></B></TH>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>Object type</FONT></B></TH>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>Status</FONT></B></TH>' FROM dual;

select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || OWNER       ||'</FONT></TD>',
           '<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || object_name ||'</FONT></TD>',
           '<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || object_type ||'</FONT></TD>',
           '<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || status      ||'</FONT></TD></TR>'
   from DBA_OBJECTS where status = 'INVALID' order by owner;
select '</TABLE>' FROM dual;
--END LIST OF INVALID OBJECTS IN THE DATABASE

--START TOTAL INVALID SYNONYMS

select '<h5><font face="VERDANA"><font color="#000000">' ||
       'Number of Invalid Synonyms in the DB <font size=-2></font></font></font></h5>'
   FROM dual;

select '<TABLE BORDER  CELLPADDING=2>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>' ||
       'Total Invalid Synonyms in DB</FONT></B></TH>' FROM dual;
select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || count(1) ||
       '</FONT></TD></TR>' from dba_objects where status = 'INVALID' and object_type='SYNONYM';
select '</TABLE>' FROM dual;
-- COMMENTS
select '<body><font face="Arial,Helvetica"><font color="#FF0000">' ||
       '<font size=3>There should be no invalid objects in the database ' ||
       'pertaining to the owners within APEX/FLOWS. If there ' ||
       'are any, recompile. Use the <b>utlrp.sql</b> script under the ' ||
       'database home to recompile.</font></font></font></body>' from dual;
--end TOTAL INVALID SYNONYMS


--START LIST OF INVALID SYNONYMS AND THEIR OWNERS IN THE DATABASE

select '<h5><font face="VERDANA"><font color="#000000">' ||
       'List of Invalid SYNONYMS in the DB <font size=-2></font></font></font></h5>'
   FROM dual;

select '<TABLE BORDER  CELLPADDING=2>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>Synonym Owner</FONT></B></TH>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>Synonym Name</FONT></B></TH>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>Object Owner</FONT></B></TH>' FROM dual;
select '<TH BGCOLOR=#33ccff><B><FONT FACE="ARIAL" COLOR="#FFFFFF" SIZE=2>Object Name </FONT></B></TH>' FROM dual;

select '<TR><TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || A.OWNER        ||'</FONT></TD>',
           '<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || A.SYNONYM_NAME ||'</FONT></TD>',
           '<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || A.TABLE_OWNER  ||'</FONT></TD>',
           '<TD BGCOLOR=#FFFFFF><FONT FACE="ARIAL" SIZE=2> ' || A.TABLE_NAME   ||'</FONT></TD></TR>'
from DBA_SYNONYMS A, DBA_OBJECTS B
where A.SYNONYM_NAME=B.OBJECT_NAME AND A.OWNER=B.OWNER AND B.STATUS='INVALID'
order by A.OWNER;
select '</TABLE>' FROM dual;

--END LIST OF INVALID SYNONYMS AND THEIR OWNERS IN THE DATABASE
exec dbms_output.put_line('</html>');

spool off