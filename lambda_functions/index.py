import base64
import json
import boto3
import os
from urllib.parse import unquote_plus

s3 = boto3.client('s3')

def lambda_handler(event, context):
    bucket_name = os.environ['UPLOAD_BUCKET_NAME']

    # Extract username from the event context
    username = event['requestContext']['authorizer']['claims']['email']

    # Checking if the body exists and is not None
    if 'body' in event and event['body'] is not None:
        if event.get("isBase64Encoded", False):
            file_content = base64.b64decode(event['body'])
        else:
            file_content = event['body'].encode('utf-8')
    else:
        return {
            'statusCode': 400,
            'body': json.dumps('No file content found in the request')
        }

    # Checking if queryStringParameters exist and filename is provided
    if 'queryStringParameters' in event and event['queryStringParameters'] is not None and 'filename' in event['queryStringParameters']:
        file_name = event['queryStringParameters']['filename']
        file_name = unquote_plus(file_name)
    else:
        return {
            'statusCode': 400,
            'body': json.dumps('Filename not provided in query string parameters')
        }

    key = f'{username}/uploads/{file_name}'
    
    # Upload the file to S3
    try:
        response = s3.put_object(Bucket=bucket_name, Key=key, Body=file_content)
        return {
            'statusCode': 200,
            'body': json.dumps('File uploaded successfully!')
        }
    except Exception as e:
        print(e)
        return {
            'statusCode': 500,
            'body': json.dumps('Error uploading the file')
        }
