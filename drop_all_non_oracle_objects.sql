accept  sysuser prompt  'Enter the sys user name : '
accept   syspwd prompt  'Enter the sys user password : '  hide

Prompt connecting to &sysuser.@dbtns.

conn &sysuser./&syspwd as sysdba

WHENEVER SQLERROR EXIT SQL.SQLCODE

spool deletion.log

SET SERVEROUTPUT ON SIZE 1000000
SET FEEDBACK OFF
SET TERMOUT ON

begin
execute immediate 'create table datafiles_loc
(file_name varchar2(30) , file_loc varchar2(1000))' ;
exception when others then
	dbms_output.put_line(sqlerrm) ;
end;
/

declare
type t_syns is table of varchar2(30) ;
t_pub_syns t_syns := t_syns() ;

Procedure execute_immediate(sql_text varchar2)
is
begin

  dbms_output.put_line(sql_text) ;
  execute immediate(sql_text);
  exception when others then
	dbms_output.put_line('Error while executing '||chr(10)||sql_text||chr(10)||sqlerrm) ;
end;


procedure drop_psyn 
is 
begin
for i in (select synonym_name from all_synonyms where owner='PUBLIC' and
                    table_owner in (select username from all_users where oracle_maintained = 'N')) loop
                    null;
  begin                    
  execute_immediate ('drop public synonym '||i.synonym_name) ;
  exception when others then
  t_pub_syns.extend(1) ;
  t_pub_syns(t_pub_syns.last) := i.synonym_name;
  end ;
end loop;
end drop_psyn;

procedure drop_users is
begin
for i in (select username from all_users where oracle_maintained = 'N') loop
  execute_immediate ('drop user '||i.username||' cascade ');
end loop;
end;

procedure drop_tbs is
begin
for i in (select tablespace_name from dba_tablespaces where tablespace_name not in ('SYSTEM' , 'SYSAUX' , 'UNDOTBS1' , 'TEMP' , 'USERS')) loop
  execute_immediate ('drop tablespace '||i.tablespace_name||' including contents and datafiles ') ;
end loop;
end ;

procedure disconnect_sessions
is
begin
for i in (select sid,serial# from v$session where username  in (select username from all_users where oracle_maintained = 'N')) loop
  execute_immediate ('alter system  kill session '''||i.sid||','||i.serial#||'''');
end loop;
dbms_lock.sleep(10) ;
end ;



begin

  dbms_output.put_line('****Backing up Data files location****') ;
  for i in (select regexp_substr(file_name , '[^\\\/\s]+.DBF')  as dbf_file,
				   regexp_substr(file_name , '^(^[a-zA-Z]\S+)[\\\/]'  ) as file_loc
				from dba_data_files
				where tablespace_name in
						(select tablespace_name from dba_tablespaces where tablespace_name not in ('SYSTEM' , 'SYSAUX' , 'UNDOTBS1' , 'TEMP' , 'USERS'))) loop

	execute immediate q'!insert into datafiles_loc values ('!'||i.dbf_file||q'!','!'||i.file_loc||q'!')!' ;
 end loop ;
 commit ;


  dbms_output.put_line('****DISCONNECTING CONNECTED SESSIONS****') ;
  disconnect_sessions ;
  dbms_output.put_line('****DROPPING PUBLIC SYNONYMS****') ;
  drop_psyn ;
  dbms_output.put_line('****DROPPING NON ORACLE USERS****') ;
  drop_users ;
  dbms_output.put_line('****DROPPING NON DEFAULT TABLESPACES****') ;
  drop_tbs ;
  
  DBMS_OUTPUT.PUT_LINE('****DROPPING REMAINING PUBLIC SYNONYMS****') ;
  if T_PUB_SYNS.count > 0 then
    FOR I IN T_PUB_SYNS.FIRST .. T_PUB_SYNS.LAST LOOP
      execute immediate 'drop public synonym '||T_PUB_SYNS(i) ;
    end loop ;
  end if ;
  
  DBMS_OUTPUT.PUT_LINE('****DROPPING NON ORACLE ROLES****') ;
  for i in (select role as role_name  from dba_roles where oracle_maintained= 'N') loop
	execute immediate 'drop role '||i.role_name ;
  end loop ;
  
  DBMS_OUTPUT.PUT_LINE('****DROPPING NON ORACLE CONTEXTS****') ;
  for i in (select namespace from dba_context where schema in (select username from dba_users where oracle_maintained = 'N')) loop
	execute immediate 'drop context '||i.namespace ;
  end loop ;


  
  exception when others then 
   dbms_output.put_line(sqlerrm) ;
end ;
/

Prompt Shutting Down and starting up instance 

shutdown abort ;
startup

Prompt Deleting db files from server  in case not deleted earlier , also deleting non oracle roles




begin
for i in (select file_loc , file_name from datafiles_loc) loop
	execute immediate 'create or replace directory db_drop_dbf '||q'! as '!'||i.file_loc||q'!'!' ;
	begin
	utl_file.fremove('DB_DROP_DBF' , i.file_name) ;
	exception when others then 
		dbms_output.put_line('Error in deleting file '||i.file_name||chr(10)||sqlerrm) ;
    end ;
end loop ;
execute immediate 'drop table datafiles_loc' ;
end;
/

 

Prompt Process is complete  . Please check logs and take necessary actions if deletion is not succesul at any level 

spool off;

pause prompt press enter to exit
