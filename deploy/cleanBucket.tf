module "bucket_2" {
    source = "./bucketWithCors/"
    region = "${var.region}"
    env = "${var.env}"
    s3_bucket_name = "${local.accountName}-${var.bucket_2_name}"
}

data "aws_iam_policy_document" "clean_bucket_policy" {
    statement {
        actions = [
            "s3:GetObject"
        ]
        effect = "Allow"
        resources = [module.bucket_2.s3_bucket_arn]
        sid = "GetAccessForCleanBucket"
    }
    
    statement {
        actions = [
            "kms:Decrypt"
        ]
        effect = "Allow"
        resources = [module.bucket_2.s3_kms_key_arn]
        sid = "KMSAccessForCleanBucket"
    }
}

resource "aws_iam_policy" "clean_bucket_policy" {
    name = "${var.name_prefix}-${module.bucket_2.s3_bucket_name}"
    description = "Access for GETting from the clean bucket"
    policy = "${data.aws_iam_policy_document.clean_bucket_policy.json}"
}

resource "aws_iam_group" "presignedurl-internal" {
    name = "${var.name_prefix}-presignedurl-internal"
}

resource "aws_iam_group_policy_attachment" "clean_bucket_policy" {
    group = "${var.name_prefix}-presignedurl-internal"
    policy_arn = "${aws_iam_policy.clean_bucket_policy.arn}"

    depends_on = [
        "aws_iam_policy.clean_bucket_policy"
    ]
}