import boto3
import os, json

sm = boto3.client("secretsmanager")

def lambda_handler(event, context):
    secret_name = os.getenv("SECRET_PREFIX") + event["userName"]

    #最小権限的にはGetで撮ったほうが良いはずだが例外で処理しないといけないのが億劫で横着しています
    secrets_list = sm.list_secrets(
        Filters= [{"Key": "name", "Values": [secret_name]}]
    )

    secret_data = {
        "username": event["userName"],
        "password": event["password"]
    }
    if len(secrets_list["SecretList"]) == 0:
        sm.create_secret(
            Name=secret_name,
            SecretString= json.dumps(secret_data)
        )
    else:
        sm.update_secret(
            SecretId=secrets_list["SecretList"][0]["ARN"],
            SecretString= json.dumps(secret_data)
        )

    return {
        "statusCode": 200,
        "body": {"Status": "Success"},
    }
