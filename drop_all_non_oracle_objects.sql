declare

type t_syns is table of varchar2(30) ;
t_pub_syns t_syns := t_syns() ;

procedure drop_psyn 
is 
begin
for i in (select synonym_name from all_synonyms where owner='PUBLIC' and
                    table_owner in (select username from all_users where oracle_maintained = 'N')) loop
                    null;
  begin                    
  execute immediate 'drop public synonym '||i.synonym_name ;
  exception when others then
  t_pub_syns.extend(1) ;
  t_pub_syns(t_pub_syns.last) := i.synonym_name;
  end ;
end loop;
end drop_psyn;

procedure drop_users is
begin
for i in (select username from all_users where oracle_maintained = 'N') loop
  execute immediate 'drop user '||i.username||' cascade ';
end loop;
end;

procedure drop_tbs is
begin
for i in (select tablespace_name from dba_tablespaces where tablespace_name not in ('SYSTEM' , 'SYSAUX' , 'UNDOTBS1' , 'TEMP' , 'USERS')) loop
  execute immediate 'drop tablespace '||i.tablespace_name||' including contents and datafiles ' ;
end loop;
end ;

procedure disconnect_sessions
is
begin
for i in (select sid,serial# from v$session where username  in (select username from all_users where oracle_maintained = 'N')) loop
  execute immediate 'alter system '''||i.sid||','||i.serial#||'''';
end loop;
dbms_lock.sleep(10) ;
end ;

begin

  dbms_output.put_line('****DISCONNECTING CONNECTED SESSIONS****') ;
  disconnect_sessions ;
  dbms_output.put_line('****DROPPING PUBLIC SYNONYMS****') ;
  drop_psyn ;
  dbms_output.put_line('****DROPPING NON ORACLE USERS****') ;
  drop_users ;
  dbms_output.put_line('****DROPPING NON DEFAULT TABLESPACES****') ;
  drop_tbs ;
  
  DBMS_OUTPUT.PUT_LINE('****DROPPING REMAINING PUBLIC SYNONYMS****') ;
  FOR I IN T_PUB_SYNS.FIRST .. T_PUB_SYNS.LAST LOOP
    execute immediate 'drop public synonym '||T_PUB_SYNS(i) ;
  end loop ;
end ;
