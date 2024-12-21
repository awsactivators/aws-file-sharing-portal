# Create Upload Bucket

resource "aws_s3_bucket" "fsp_upload_bucket" {
	bucket = "pendulum-uploads"

    lifecycle {
      ignore_changes = [ timeouts, force_destroy  ]
    }

	tags = local.common_tags
}


resource "aws_s3_bucket_server_side_encryption_configuration" "fsp_bucket_SSE" {
  bucket = aws_s3_bucket.fsp_upload_bucket.bucket

    rule {
			apply_server_side_encryption_by_default {	
				sse_algorithm = "aws:kms"
		  }
		}

}

resource "aws_s3_bucket_versioning" "fsp_bucket_versioning" {
  bucket = aws_s3_bucket.fsp_upload_bucket.id

  versioning_configuration {
	status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "fsp_bucket_ownership" {
  bucket = aws_s3_bucket.fsp_upload_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}


resource "aws_s3_bucket_acl" "fsp_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.fsp_bucket_ownership]
  bucket = aws_s3_bucket.fsp_upload_bucket.id
  acl = "private"
}


#Lambda function zip bucket
resource "aws_s3_bucket" "fsp_lambda_function_bucket" {
	bucket = "fsp-lambda-function"

    lifecycle {
      ignore_changes = [ timeouts, force_destroy  ]
    }

	tags = local.common_tags
}

# Zip the Lambda function on the fly
data "archive_file" "fsp_source" {
  type        = "zip"
  source_dir  = local.lambda_src_dir
  output_path = local.lambda_function_zip_path
}

# Upload the zip file to S3 bucket
resource "aws_s3_object" "fsp_lambda_function_code" {
  bucket = aws_s3_bucket.fsp_lambda_function_bucket.bucket
  source = data.archive_file.fsp_source.output_path
  key    = "index.zip"
  acl    = "private"
  depends_on = [aws_s3_bucket.fsp_lambda_function_bucket]
}