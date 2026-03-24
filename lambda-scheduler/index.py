"""
Serviço 3 - Rotina diária: insere um arquivo no S3.
O nome do arquivo é a data/hora exata da execução (UTC).
"""
import os
import boto3
from datetime import datetime

def handler(event, context):
    bucket_name = os.environ["BUCKET_NAME"]
    # Data/hora exata da execução no formato: YYYY-MM-DD_HH-MM-SS
    now = datetime.utcnow()
    file_name = now.strftime("%Y-%m-%d_%H-%M-%S.txt")

    content = f"""Arquivo gerado pela rotina diária - Portfolio Cloud
Data/hora da execução (UTC): {now.isoformat()}Z
Região: {os.environ.get('AWS_REGION', 'N/A')}
"""

    s3 = boto3.client("s3")
    s3.put_object(
        Bucket=bucket_name,
        Key=file_name,
        Body=content.encode("utf-8"),
        ContentType="text/plain; charset=utf-8",
    )

    return {
        "statusCode": 200,
        "body": f"Arquivo {file_name} inserido no bucket {bucket_name} com sucesso.",
    }
