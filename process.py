import os
import subprocess
import uuid
import boto3
from urllib.parse import urlparse

def parse_s3_uri(s3_uri: str):
    """
    Parses a string in the format s3://bucket_name/path/to/file.pdf
    and returns (bucket, key).
    """
    parsed = urlparse(s3_uri)
    if parsed.scheme != 's3':
        raise ValueError(f"URI '{s3_uri}' is not a valid s3:// link.")
    bucket = parsed.netloc
    key = parsed.path.lstrip('/')
    return bucket, key

def main():
    input_uri = os.environ.get("INPUT_S3_URI")
    output_uri = os.environ.get("OUTPUT_S3_URI")

    if not input_uri or not output_uri:
        raise ValueError("Please provide the INPUT_S3_URI and OUTPUT_S3_URI environment variables.")

    s3 = boto3.client("s3")

    input_bucket, input_key = parse_s3_uri(input_uri)
    output_bucket, output_key = parse_s3_uri(output_uri)

    local_input_file = f"/tmp/{uuid.uuid4()}.pdf"
    local_output_file = f"/tmp/{uuid.uuid4()}.pdf"

    print(f"Downloading {input_uri} to {local_input_file}")
    s3.download_file(input_bucket, input_key, local_input_file)

    print(f"Running OCR: {local_input_file} -> {local_output_file}")
    subprocess.run(["ocrmypdf", "--skip-text", local_input_file, local_output_file], check=True)
    print("OCR completed successfully.")

    print(f"Uploading the result to {output_uri}")
    s3.upload_file(local_output_file, output_bucket, output_key)
    print("Upload completed.")

if __name__ == "__main__":
    main()
