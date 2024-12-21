import base64
import json
import boto3
import os
from urllib.parse import unquote_plus

s3 = boto3.client('s3')
lambda_client = boto3.client('lambda')

def lambda_handler(event, context):
    # Environment variables s3 & lambda
    bucket_name = os.environ['UPLOAD_BUCKET_NAME']
    #forecast_lambda_name = os.environ['FORECAST_LAMBDA_NAME']  
    
    # Extract username from the event
    username = event['requestContext']['authorizer']['claims']['email']
    
    # Check for forecast request
    # forecast_request = event['queryStringParameters'].get('forecast_request', 'false').lower() == 'true'
    
    # if forecast_request:
    #     # If forecast_request is true, trigger another Lambda function
    #     try:
    #         # Prepare the payload for the forecast Lambda function
    #         payload = json.dumps({
    #             "user": username,
    #         })
    #         response = lambda_client.invoke(
    #             FunctionName=forecast_lambda_name,
    #             InvocationType='Event',  #for asynchronous execution
    #             Payload=payload,
    #         )
    #         return {
    #             'statusCode': 200,
    #             'body': json.dumps('Forecast request sent successfully!')
    #         }
    #     except Exception as e:
    #         print(e)
    #         return {
    #             'statusCode': 500,
    #             'body': json.dumps('Error triggering forecast function')
    #         }
    # else:
        # Proceed with the S3 upload logic
    if event.get("isBase64Encoded", False):
            file_content = base64.b64decode(event['body'])
    else:
            file_content = event['body'].encode('utf-8')
        
    file_name = event['queryStringParameters']['filename']
    file_name = unquote_plus(file_name)
    key = f'{username}/uploads/{file_name}'
        
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
