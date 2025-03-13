import boto3
import json
import os

sqs = boto3.client('sqs')
queue_url = os.environ['SQS_QUEUE_URL']

response = sqs.receive_message(QueueUrl=queue_url, MaxNumberOfMessages=1)

if 'Messages' in response:
    for msg in response['Messages']:
        body = json.loads(msg['Body'])
        pdf_url = body['pdf_url']
        output_location = body['output_location']

        # скачиваем PDF, запускаем OCRMyPDF и сохраняем в S3
        os.system(f"wget {pdf_url} -O input.pdf")
        os.system(f"ocrmypdf input.pdf output.pdf")
        os.system(f"aws s3 cp output.pdf {output_location}")

        sqs.delete_message(QueueUrl=queue_url, ReceiptHandle=msg['ReceiptHandle'])
