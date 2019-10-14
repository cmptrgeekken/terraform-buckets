module "bucket_1" {
    source = "./bucketWithCors/"
    region = "${var.region}"
    env = "${var.env}"
    project = "${var.project}"
    s3_bucket_name = "${local.accountName}-${var.bucket_1_name}"
}

# Bucket_1 Notification to Execute Lambda
resource "aws_lambda_permission" "allow_bucket" {
    statement_id = "AllowExecutionFromS3Bucket"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.filemanager_lambda.arn}"
    principal = "s3.amazonaws.com"
    source_arn = "${module.bucket_1.s3_bucket_arn}"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
    bucket = "${module.bucket_1.s3_bucket_name}"

    dynamic "lambda_function" {
        for_each = var.bucket_notification_extensions

        content {
            lambda_function_arn = "${aws_lambda_function.filemanager_lambda.arn}"
            events = "${var.bucket_notification_events}"
            filter_suffix = "${lambda_function.value}"
        }
    }
}


data "aws_iam_policy_document" "dirty_bucket_policy" {
    statement {
        actions = [
            "s3:PutObject",
            "s3:PutObjectTagging"
        ]
        effect = "Allow"
        resources = ["${module.bucket_1.s3_bucket_arn}/*"]
        sid = "PutAccessForDirtyBucket"
    }
    statement {
        actions = [
            "kms:GenerateDataKey",
            "kms:Decrypt"
        ]
        effect = "Allow"
        resources = [module.bucket_1.s3_kms_key_arn]
        sid = "KMSAccessForDirtyBucket"
    }
}

resource "aws_iam_policy" "dirty_bucket_policy" {
    name = "${var.name_prefix}-${module.bucket_1.s3_bucket_name}"
    description = "Access for PUTting to the dirty bucket"
    policy = "${data.aws_iam_policy_document.dirty_bucket_policy.json}"
}

resource "aws_iam_group" "presignedurl-public" {
    name = "${var.name_prefix}-presignedurl-public"
}

resource "aws_iam_group_policy_attachment" "dirty_bucket_policy" {
    group = "${var.name_prefix}-presignedurl-public"
    policy_arn = "${aws_iam_policy.dirty_bucket_policy.arn}"

    depends_on = [
        "aws_iam_policy.dirty_bucket_policy"
    ]
}