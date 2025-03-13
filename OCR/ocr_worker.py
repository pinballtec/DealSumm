import boto3
import json
import os
import subprocess

sqs = boto3.client('sqs')
queue_url = os.environ['SQS_QUEUE_URL']

while True:
    response = sqs.receive_message(
        QueueUrl=queue_url,
        MaxNumberOfMessages=1,
        WaitTimeSeconds=10
    )

    if 'Messages' in response:
        for msg in response['Messages']:
            body = json.loads(msg['Body'])
            pdf_url = body['pdf_url']
            output_location = body['output_location']

            try:
                subprocess.run(["wget", pdf_url, "-O", "/tmp/input.pdf"], check=True)
                subprocess.run(["ocrmypdf", "/tmp/input.pdf", "/tmp/output.pdf"], check=True)
                subprocess.run(["aws", "s3", "cp", "/tmp/output.pdf", output_location], check=True)
                sqs.delete_message(QueueUrl=queue_url, ReceiptHandle=msg['ReceiptHandle'])
                print("Successfully processed PDF.")
            except subprocess.CalledProcessError as e:
                print(f"Processing error: {e}")
