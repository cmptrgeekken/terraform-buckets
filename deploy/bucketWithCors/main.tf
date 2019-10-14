# Represents a customer master key for encrypting data
resource "aws_kms_key" "s3_kms_key" {
    description = "Encryption key for ${var.s3_bucket_name}"
    enable_key_rotation = "${true}"
    tags = "${merge(var.tags, map("Name", format("%s%s", "Encryption key for ", "${var.s3_bucket_name}")))}"
}

# Defines an alias for referencing the customer master key
resource "aws_kms_alias" "kms_alias" {
    name = "alias/s3key-${var.s3_bucket_name}"
    target_key_id = "${aws_kms_key.s3_kms_key.key_id}"
    depends_on = [
        "aws_kms_key.s3_kms_key"
    ]
}

# Define the IAM policy for the bucket
data "aws_iam_policy_document" "s3_iam_policy" {
    statement {
        actions = [
            "s3:ListAllMyBuckets",
            "s3:GetBucketAcl",
            "s3:GetBucketPolicy",
            "s3:GetBucketLocation"
        ]
        effect = "Allow"
        resources = ["*"]
        sid = "ListBuckets"
    }
    statement {
        actions = [
            "s3:ListBucket",
            "s3:GetEncryptionConfiguration"
        ]
        effect = "Allow"
        resources = ["${aws_s3_bucket.s3_bucket.arn}"]
        sid = "BucketAccess"
    }
    statement {
        actions = [
            "s3:PutObject",
            "s3:DeleteObject",
            "s3:GetObject",
            "s3:GetObjectAcl",
            "s3:PutObjectTagging",
            "s3:GetObjectTagging",
            "s3:GetObjectTorrent",
            "s3:GetObjectVersion",
            "s3:GetObjectVersionAcl",
            "s3:GetObjectVersionTagging",
            "s3:PutObjectVersionTagging",
            "s3:GetObjectVersionTorrent",
            "s3:ListMultipartUploadParts"
        ]
        effect = "Allow"
        resources = ["${aws_s3_bucket.s3_bucket.arn}/*"]
        sid = "ObjectAccess"
    }
    statement {
        actions = ["kms:ListAliases"]
        effect = "Allow"
        resources = ["*"]
        sid = "DisplayKeyListInConsole"
    }
    statement {
        actions = [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt",
            "kms:GenerateDataKey",
            "kms:DescribeKey",
            "kms:GetKeyPolicy",
            "kms:GetKeyRotationStatus",
            "kms:ListKeyPolicies"
        ]
        effect = "Allow"
        resources = ["${aws_kms_key.s3_kms_key.arn}"]
        sid = "KMSDecryptEncryptAndGeneralAccess"
    }
    statement {
        actions = [
            "kms:CreateGrant",
            "kms:ListGrants",
            "kms:RevokeGrant"
        ]
        condition {
            test = "Bool"
            variable = "kms:GrantIsForAWSResource"
            values = ["true"]
        }
        effect = "Allow"
        resources = ["${aws_kms_key.s3_kms_key.arn}"]
        sid = "KMSGrants"
    }
    depends_on = [
        "aws_kms_key.s3_kms_key",
        "aws_s3_bucket.s3_bucket"
    ]
}

resource "aws_iam_policy" "s3_iam_policy" {
    name = "buckets-s3-crud-${var.s3_bucket_name}"
    description = "Allow CRUD access to files in an S3 bucket"
    policy = "${data.aws_iam_policy_document.s3_iam_policy.json}"
}

resource "aws_s3_bucket" "s3_bucket" {
    bucket = "${var.s3_bucket_name}"

    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                kms_master_key_id = "${aws_kms_key.s3_kms_key.arn}"
                sse_algorithm = "aws:kms"
            }
        }
    }

    tags = "${merge(var.tags, map("Name", format("%s", "${var.s3_bucket_name}")))}"

    versioning {
        enabled = "${true}"
    }

    lifecycle_rule {
        id = "Lifecycle Rule"
        prefix = ""
        enabled = "${true}"

        transition {
            days = "${30}"
            storage_class = "STANDARD_IA"
        }
    }

    force_destroy = "${true}"

    cors_rule  {
        allowed_headers = ["*"]
        allowed_methods = "${var.s3_cors_allowed_methods}"
        allowed_origins = "${var.s3_cors_allowed_origins}"
        expose_headers = ["ETag"]
        max_age_seconds = "${3000}"
    }
}

resource "aws_s3_bucket_policy" "s3_bucket" {
    bucket = "${aws_s3_bucket.s3_bucket.id}"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Id": "BucketPolicy",
    "Statement": [
        {
            "Sid": "SecureTransport",
            "Action": "s3:*",
            "Effect": "Deny",
            "Principal": "*",
            "Resource": "${aws_s3_bucket.s3_bucket.arn}/*",
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        }
    ]
}
EOF
    depends_on = [
        "aws_s3_bucket.s3_bucket"
    ]
}