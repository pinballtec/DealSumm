import boto3
import json
import os
import time  

sqs = boto3.client('sqs', region_name=os.getenv('AWS_REGION'))
queue_url = os.environ['SQS_QUEUE_URL']

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

if __name__ == "__main__":
    while True:  
        pdf_url = "s3://mybucket/input/output.pdf"
        output_location = "s3://mybucket/output/output.pdf"
        send_pdf_for_ocr(pdf_url, output_location)
        
        print("waiting before second sending")
        time.sleep(10)  
