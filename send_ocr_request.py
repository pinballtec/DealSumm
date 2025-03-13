import boto3
import json

sqs = boto3.client('sqs', region_name='us-east-1')

queue_url = 'https://sqs.us-east-1.amazonaws.com/your-account-id/OCRQueue'

def send_pdf_for_ocr(pdf_url, output_location):
    message = {
        "pdf_url": pdf_url,
        "output_location": output_location
    }
    response = sqs.send_message(
        QueueUrl=queue_url,
        MessageBody=json.dumps(message)
    )
    print(f'Message ID: {response["MessageId"]}')

# Example usage
send_pdf_for_ocr('https://example.com/mydoc.pdf', 's3://mybucket/output/')
