-- Included by the E3 demo seed and cleanup before any write. Hard-fails (psql exit 3)
-- unless this session is the local Docker Desktop Supabase database: client target
-- 127.0.0.1:54322, a postgres or e3_demo_dryrun_* database, and a server address equal
-- to the supabase_db_flutterapp container IP that tools/demo/e3_local_demo.sh passes in.
\set ON_ERROR_STOP on
\if :{?e3_local_db_ip}
\else
  \echo 'Refusing E3 demo SQL: run it through tools/demo/e3_local_demo.sh'
  do $$ begin raise exception 'E3 demo local guard: e3_local_db_ip is not set'; end $$;
\endif
select :'HOST' = '127.0.0.1'
   and :'PORT' = '54322'
   and (current_database() = 'postgres' or current_database() like 'e3\_demo\_dryrun\_%')
   and host(inet_server_addr()) = :'e3_local_db_ip' as e3_local_target \gset
\if :e3_local_target
\else
  \echo 'Refusing E3 demo SQL: target is not the local Docker Supabase database'
  do $$ begin raise exception 'E3 demo local guard: nonlocal target'; end $$;
\endif
