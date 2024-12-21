# Adding social identity providers (google) to a user pool #

**Step 1: Register with a social IdP**

For more information about OAuth 2.0 in the Google Cloud platform, see [Learn about authentication & authorization in the Google Workspace for Developers documentation](https://developers.google.com/workspace/guides/auth).

1. Create a developer account with Google.
2. Sign in to the Google Cloud Platform console.
3. From the top navigation bar, choose **Select a project**. If you already have a project in the Google platform, this menu displays your default project instead.
4. Select **NEW PROJECT**.
5. Enter a name for your product and then choose **CREATE**.
6. On the left navigation bar, choose **APIs and Services**, then **OAuth consent screen**.
7. Enter App information, an App domain, Authorized domains, and Developer contact information. Your Authorized domains must include `amazoncognito.com` and the root of your custom domain, for example, `example.com`. Choose **SAVE AND CONTINUE**.
8. Under **Scopes**, choose **Add or remove scopes**, and choose, at minimum, the following OAuth scopes:
   - `.../auth/userinfo.email`
   - `.../auth/userinfo.profile`
   - `openid`
9. Under **Test users**, choose **Add users**. Enter your email address and any other authorized test users, then choose **SAVE AND CONTINUE**.
10. Expand the left navigation bar again, and choose **APIs and Services**, then **Credentials**.
11. Choose **CREATE CREDENTIALS**, then **OAuth client ID**.
12. Choose an Application type and give your client a **Name**.
13. Under **Authorized JavaScript origins**, choose **ADD URI**. Enter your user pool domain.

    ```
    https://mydomain.us-east-1.amazoncognito.com
    ```

14. Under **Authorized redirect URIs**, choose **ADD URI**. Enter the path to the `/oauth2/idpresponse` endpoint of your user pool domain.

    ```
    https://mydomain.us-east-1.amazoncognito.com/oauth2/idpresponse
    ```

15. Choose **CREATE**.
16. Securely store the values the Google displays under **Your client ID** and **Your client secret**. Provide these values to Amazon Cognito when you add a Google IdP.


**Step 2: Add the google social IdP to cognito user pool**
This was added via Terraform using the resource **aws_cognito_identity_provider** and linking it to the cognito user pool ID

AWS link https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-social-idp.html


# Lambda Function #

This Lambda function is designed to handle file uploads to an Amazon S3 bucket. Here's how it works:

- **Initialization**: The function starts by initializing a client for the S3 service using `Boto3`, which is the Amazon Web Services (AWS) SDK for Python.
- **Lambda Handler**: The `lambda_handler` function acts as the entry point for the Lambda execution. It performs several key actions:
  - Retrieves the S3 bucket name from an environment variable.
  - Extracts the username from the event context, typically derived from an email claimed within the authorizer claims of the request context.
- **Body Processing**: The function checks if there is a body in the event:
  - If the body is base64-encoded, it decodes the body from base64.
  - If not, it encodes the body in 'utf-8'.
- **Filename Handling**: It looks for query string parameters that might include a filename. If a filename is present, it unquotes the filename to ensure it's correctly formatted.
- **S3 Upload Path**: Constructs the key for the S3 object to be uploaded. The key includes the username and filename, indicating the file is within an 'uploads' directory for the user.
- **Uploading**: Attempts to upload the file to the S3 bucket. Upon completion:
  - If successful, returns a status code of `200` and a success message.
  - If an error occurs during the upload, it catches the exception, logs it, and returns a status code of `500` with an error message indicating the upload failed.

This function is triggered by an event (an HTTP request), and is designed to securely and efficiently handle file uploads directly to a specified S3 bucket.
