CREATE EXTENSION pg_tle;
-- install with aws_common
CREATE EXTENSION aws_lambda CASCADE;

--change 'postgres' to your username
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA pgtle TO postgres;


SELECT pgtle.install_extension(
  'sync_secrets',
  '1.0',
  'Sync credential to Secrets Manager',
$_pgtle_$
  CREATE SCHEMA sync_secrets;
  
  CREATE FUNCTION sync_secrets.hook_function(username text, password text, password_type pgtle.password_types, valid_until timestamptz, valid_null boolean)
  RETURNS void AS $$
    DECLARE
      context json;
    BEGIN
      context := '{"userName": "'|| hook_function.username ||'", "password": "'||  hook_function.password || '"}';
      -- Call lambda function, if login success
      PERFORM aws_lambda.invoke(
          'arn:aws:lambda:ap-northeast-1:xxxxxx:function:pgsql-sync-login-user-info-SyncUserFunction-xxxxxx',
          context::json
      );
    END
  $$ LANGUAGE plpgsql;

  --　上記の関数を認証時のフック処理として登録
  SELECT pgtle.register_feature('sync_secrets.hook_function', 'passcheck');
  REVOKE ALL ON SCHEMA sync_secrets FROM PUBLIC;
$_pgtle_$,
'{aws_lambda}'
);