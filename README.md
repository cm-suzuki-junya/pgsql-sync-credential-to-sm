## 概要

pg_tleのパスワードフック処理を利用して認証情報の変更をAWS Secrets Managerに伝播する拡張機能のサンプル


## 前提

pg_tle 1.3.0以上およびaws_lambdaがインストールされておりPostgreSQLからLambda関数が呼びし可能な状態となっている。  
周辺リソースはRDSが前提となっているが適切なセットアップを行えばRDS以外でも適用可能

## 含まれるリソース

- RDSに割り当てるためのIAMロール
- 実行されるAWS Lambda関数
- RDS内で拡張機能作成のために利用するSQL(pg_extention.sql)

## 環境セットアップ

### SAMによるデプロイ

```bash
sam build && sam deploy
```

### RDS手動セットアップ箇所

RDSに対して`CallLoginNotificationRdsRole`で作成されるIAMロールをLambda機能として割り当てる。

また割り当てられているパラメータグループに以下の設定を行う

|パラメータ|値|備考|
|-------|--|---|
|shared_preload_library|pg_tle|既存パラメータがある場合そこへの追加|
|pgtle.enable_password_check|on| |
|rds.custom_dns_resolution| 1 | VPCエンドポイントを利用する場合 |

パラメータグループ設定後にRDS再起動した後にDBに接続しスーパーユーザで`pg_extention.sql`の内容を実行する。

その後以下を実行し通知用の独自拡張機能を有効化する。

```sql
CREATE EXTENSION sync_secrets;
```

なお有効化後は動作確認が取れるまで既存のコネクションを切断せず保持すること。  
指定がうまくできていない場合DBに接続不可となる可能性がある。


## 動作確認

`ALTER USER postgres WITH PASSWORD 'password'`でDB上のユーザのパスワードを変更した後、  
Secrets Managerに以下のシークレットが格納され変更されたユーザ名と変更後のパスワードが格納されている。

`/rds/user/{{パスワードを変更したユーザ名}}`

※ プレフィックス()`/rds/user/`)部分はSAMのデプロイ時に渡すパラメータで変更可能

## 備考

以下記事記載のために作成しされたサンプルとなりますのでこちらもご参照ください。

https://dev.classmethod.jp/articles/sync-user-postgresql-to-secrets-manager/