SET sqlprompt "_user'@'_connect_identifier>"
SET sqlformat ansiconsole
SET LONG 1000000
SET LONGCHUNKSIZE 1000000
cd e:/oracle/sql
set pagesize 40

set feedback off

alter session set NLS_DATE_FORMAT = 'yyyy-mm-dd HH24:mi:ss';

set feedback on


alias plan=SELECT * FROM table(DBMS_XPLAN.DISPLAY_CURSOR);
alias ases=SELECT USERNAME,MACHINE, EVENT, LAST_CALL_ET from v$session where status='ACTIVE' and type !='BACKGROUND';
alias asql=select ses.username, ses.sql_id, sql.sql_text from v$session ses, v$sql sql where ses.status='ACTIVE' and ses.type !='BACKGROUND' and ses.sql_id=sql.sql_id(+);
alias findobj=select owner,object_name,object_type,status from dba_objects where object_name like UPPER('%' || :1 || '%');
alias cursch=alter session set current_Schema=:1;
alias asqlmon=select sid,username, program, sql_id, substr(sql_text,0,40),ELAPSED_TIME,cpu_time, buffer_gets, disk_reads from v$sql_monitor where status='EXECUTING';
alias lastsqlmon=select SQL_EXEC_START,sid,username, program,sql_id,substr(sql_text,0,40) SQLTEXT,ELAPSED_TIME,cpu_time, buffer_gets, disk_reads from v$sql_monitor where rownum<:1 order by SQL_EXEC_START desc;
alias sqlmonrpt=SELECT DBMS_SQLTUNE.report_sql_monitor(
 	 sql_id       => :1,
 	 type         => 'TEXT',
 	 report_level => 'ALL') AS report
         FROM dual;

alias locks=select	OS_USER_NAME os_user,
		PROCESS os_pid,
		ORACLE_USERNAME oracle_user,
		l.SID oracle_id,
		decode(TYPE,
			'MR', 'Media Recovery',
			'RT', 'Redo Thread',
			'UN', 'User Name',
			'TX', 'Transaction',
			'TM', 'DML',
			'UL', 'PL/SQL User Lock',
			'DX', 'Distributed Xaction',
			'CF', 'Control File',
			'IS', 'Instance State',
			'FS', 'File Set',
			'IR', 'Instance Recovery',
			'ST', 'Disk Space Transaction',
			'TS', 'Temp Segment',
			'IV', 'Library Cache Invalidation',
			'LS', 'Log Start or Switch',
				'RW', 'Row Wait',
			'SQ', 'Sequence Number',
			'TE', 'Extend Table',
			'TT', 'Temp Table', type) lock_type,
		decode(LMODE,
			0, 'None',
			1, 'Null',
			2, 'Row-S (SS)',
			3, 'Row-X (SX)',
			4, 'Share',
			5, 'S/Row-X (SSX)',
			6, 'Exclusive', lmode) lock_held,
		decode(REQUEST,
			0, 'None',
			1, 'Null',
			2, 'Row-S (SS)',
			3, 'Row-X (SX)',
			4, 'Share',
			5, 'S/Row-X (SSX)',
			6, 'Exclusive', request) lock_requested,
		decode(BLOCK,
			0, 'Not Blocking',
			1, 'Blocking',
			2, 'Global', block) status,
		OWNER,
		OBJECT_NAME
		from	v$locked_object lo,
		dba_objects do,
		v$lock l
		where 	lo.OBJECT_ID = do.OBJECT_ID
		AND     l.SID = lo.SESSION_ID
		and block=1;
		
alias tablespaces=SELECT a.TABLESPACE_NAME,
				a.BYTES / 1024 / 1024 Mbytes_used,	
				b.BYTES / 1024 / 1024 Mbytes_free,
				ROUND ( ( (a.BYTES - b.BYTES) / a.BYTES) * 100, 2) percent_used
						FROM (  SELECT TABLESPACE_NAME, SUM (BYTES) BYTES
							FROM dba_data_files
							GROUP BY TABLESPACE_NAME) a
							LEFT OUTER JOIN
							(  SELECT TABLESPACE_NAME, SUM (BYTES) BYTES, MAX (BYTES) largest
								FROM dba_free_space
							GROUP BY TABLESPACE_NAME) b
							ON a.TABLESPACE_NAME = b.TABLESPACE_NAME
					WHERE 1 = 1 AND a.tablespace_name LIKE '%'
					ORDER BY ( (a.BYTES - b.BYTES) / a.BYTES) DESC;

alias datafiles=SELECT  Substr(df.tablespace_name,1,20) "Tablespace Name",
							Substr(df.file_name,1,80) "File Name",
							Round(df.bytes/1024/1024,0) "Size (M)",
							decode(e.used_bytes,NULL,0,Round(e.used_bytes/1024/1024,0)) "Used (M)",
							decode(f.free_bytes,NULL,0,Round(f.free_bytes/1024/1024,0)) "Free (M)",
							decode(e.used_bytes,NULL,0,Round((e.used_bytes/df.bytes)*100,0)) "% Used",
							autoextensible "Autoext",
							Round(maxbytes/1024/1024,0) "Max Size",
							decode(e.used_bytes,NULL,0,Round((maxbytes/df.bytes)*100,0)) "% Used of Max"
					FROM    DBA_DATA_FILES DF,
						(SELECT file_id,
								sum(bytes) used_bytes
							FROM dba_extents
							GROUP by file_id) E,
						(SELECT Max(bytes) free_bytes,
								file_id
							FROM dba_free_space
							GROUP BY file_id) f
					WHERE    e.file_id (+) = df.file_id
					AND      df.file_id  = f.file_id (+) AND DF.TABLESPACE_NAME like  ('%'||:1||'%')
					ORDER BY df.tablespace_name,
							df.file_name;

alias time=select to_char(sysdate,'yyyy-mm-dd HH24:mi:ss') "Current time" from dual;

alias longops=SELECT s.sid,
			s.serial#,
			s.machine,
			ROUND(sl.elapsed_seconds/60) || ':' || MOD(sl.elapsed_seconds,60) elapsed,
			ROUND(sl.time_remaining/60) || ':' || MOD(sl.time_remaining,60) remaining,
			ROUND(sl.sofar/sl.totalwork*100, 2) progress_pct
			FROM   v$session s,
				v$session_longops sl
				WHERE  s.sid     = sl.sid
				AND    s.serial# = sl.serial#;
				
alias seslist=select sid,serial#,ses.username, ses.status , machine, LAST_cALL_eT, LOGON_TIME, EVENT , ses.sql_id, substr(sql_text,0,40) "SQLTEXT" from v$session ses, v$sql sql where ses.type !='BACKGROUND' and ses.sql_id=sql.sql_id(+) and username like '%' || :1 || '%';

alias quickwaits=select
				count(*),
				CASE WHEN state != 'WAITING' THEN 'WORKING'
						ELSE 'WAITING'
				END AS state,
				CASE WHEN state != 'WAITING' THEN 'On CPU / runqueue'
						ELSE event
				END AS sw_event
				FROM
				v$session
				where type != 'BACKGROUND'
				GROUP BY
				CASE WHEN state != 'WAITING' THEN 'WORKING'
						ELSE 'WAITING'
				END,
				CASE WHEN state != 'WAITING' THEN 'On CPU / runqueue'
						ELSE event
				END
				ORDER BY
				1 DESC, 2 DESC;

alias quicksqls=select sql_hash_value, count(*) from v$session where status = 'ACTIVE' group by sql_hash_value order by 2 desc;

alias listawrsnap=
select snap_id,
  snap_level,
  to_char(begin_interval_time, 'dd/mm/yy hh24:mi:ss') begin
from 
   dba_hist_snapshot where begin_interval_time > sysdate - :1
order by  1;
				
alias account= select * from dba_users where username like ('%'||:1||'%')

script kill.js
