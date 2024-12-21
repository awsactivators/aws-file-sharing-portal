import os
import json
import requests
import time
import base64
#from documentpro_common.aws_services.secrets_manager import get_secret

# Environment variables
CLIENT_ID = ""
#CLIENT_SECRET_NAME = "fsp-app-client"
CLIENT_SECRET = ""
COGNITO_URL = "https://domain.us-east-1.amazoncognito.com/oauth2/token"

# Global variables for caching the token
global_token = None
global_token_expiry = 0

class CognitoTokenManager:
    def __init__(self):
        self.client_id = CLIENT_ID
        self.client_secret = CLIENT_SECRET
        self.token_url = COGNITO_URL

    # Check if the current token has expired
    def _is_token_expired(self):
        global global_token_expiry
        return time.time() >= global_token_expiry

    # Get encoded client credentials
    def _get_encoded_credentials(self):
        credentials = f"{self.client_id}:{self.client_secret}"
        return base64.b64encode(credentials.encode()).decode()

    # Fetch a new token from Cognito
    def _fetch_new_token(self):
        global global_token
        global global_token_expiry

        headers = {
            'Content-Type': "application/x-www-form-urlencoded",
            'Authorization': f'Basic {self._get_encoded_credentials()}'
        }
        payload = "grant_type=client_credentials&scope=fsp-scope/custom_scope"
        response = requests.post(self.token_url, data=payload, headers=headers)

        if response.status_code == 200:
            response_data = response.json()
            global_token = response_data["access_token"]
            # Update expiry time based on 'expires_in' field in the response
            global_token_expiry = time.time() + response_data["expires_in"]
        else:
            raise Exception(f"Failed to fetch Cognito access token: {response.text}")

    # Retrieve the current token or fetch a new one if necessary
    def get_token(self):
        global global_token
        if not global_token or self._is_token_expired():
            self._fetch_new_token()
        return global_token


if __name__ == '__main__':
    token = CognitoTokenManager()
    print(token.get_token())