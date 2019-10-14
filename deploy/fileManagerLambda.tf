locals {
    fileManagerLambda = "filemanager_lambda"
    fileManagerLambdaFull = "${local.accountName}-${local.fileManagerLambda}"
}

data "aws_iam_policy_document" "invoke_function" {
    statement {
        actions = ["lambda:InvokeFunction"]
        effect = "Allow"
        resources = ["${aws_lambda_function.filemanager_lambda.arn}"]
        sid = "InvokeFunction"
    }
}

data "aws_iam_policy_document" "create_logs" {
    statement {
        actions = [
            "logs:CreateLogStream",
            "logs:CreateLogGroup",
            "logs:PutLogEvents"
        ]
        effect = "Allow"
        resources = ["*"]
        sid = "CreateLogs"
    }
}

data "aws_iam_policy_document" "access_vpc" {
    statement {
        actions = [
            "ec2:CreateNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeSubnets",
            "ec2:DescribeVpcs"
        ]
        effect = "Allow"
        resources = ["${aws_lambda_function.filemanager_lambda.arn}"]
        sid = "AccessVpc"
    }
}

data "aws_iam_policy_document" "lambdatrustpolicy" {
    statement {
        actions = ["sts:AssumeRole"]
        effect = "Allow"
        principals {
            type = "Service"
            identifiers = ["lambda.amazonaws.com"]
        }
        sid = ""
    }
}

resource "aws_iam_role" "filemanager_lambda" {
    name = "${var.name_prefix}-lambda-${local.fileManagerLambdaFull}"
    description = "Role for ${local.fileManagerLambdaFull} Lambda"
    assume_role_policy = "${data.aws_iam_policy_document.lambdatrustpolicy.json}"
}

resource "aws_iam_policy" "filemanager_lambda_invoke" {
    name = "${var.name_prefix}-lambda-invoke"
    description = "Allow invocation of Lambda functions"
    policy = "${data.aws_iam_policy_document.invoke_function.json}"
}

resource "aws_iam_role_policy_attachment" "filemanager_lambda_invoke" {
    role = "${aws_iam_role.filemanager_lambda.name}"
    policy_arn = "${aws_iam_policy.filemanager_lambda_invoke.arn}"
}

resource "aws_iam_policy" "filemanager_lambda_logs" {
    name = "${var.name_prefix}-lambda-logs"
    description = "Allow writing to CloudWatch Logs"
    policy = "${data.aws_iam_policy_document.create_logs.json}"
}

resource "aws_iam_role_policy_attachment" "filemanager_lambda_logs" {
    role = "${aws_iam_role.filemanager_lambda.name}"
    policy_arn = "${aws_iam_policy.filemanager_lambda_logs.arn}"
}

resource "aws_iam_policy" "filemanager_lambda_vpc" {
    name = "${var.name_prefix}-lambda-vpc"
    description = "Allow access to VPCs for Lambda"
    policy = "${data.aws_iam_policy_document.access_vpc.json}"
}

resource "aws_iam_role_policy_attachment" "filemanager_lambda_vpc" {
    role = "${aws_iam_role.filemanager_lambda.name}"
    policy_arn = "${aws_iam_policy.filemanager_lambda_vpc.arn}"
}

resource "aws_iam_role_policy_attachment" "filemanager_lambda_bucket_1" {
    role = "${aws_iam_role.filemanager_lambda.name}"
    policy_arn = "${module.bucket_1.s3_iam_policy_arn}"
}

resource "aws_iam_role_policy_attachment" "filemanager_lambda_bucket_2" {
    role = "${aws_iam_role.filemanager_lambda.name}"
    policy_arn = "${module.bucket_2.s3_iam_policy_arn}"
}


resource "aws_lambda_function" "filemanager_lambda" {
    filename = "${local.lambdaPackageName}.zip"
    function_name = "${local.fileManagerLambdaFull}"
    description = "${local.fileManagerLambdaFull} Lambda"
    role = "${aws_iam_role.filemanager_lambda.arn}"
    handler = "${local.fileManagerLambda}.handleNewVideo"
    source_code_hash = "${base64sha256(filebase64("${local.lambdaPackageName}.zip"))}"
    runtime = "${var.lambda_runtime}"
    memory_size = "${var.lambda_memory_size}"
    timeout = "${var.lambda_timeout}"

    vpc_config {
        subnet_ids = []
        security_group_ids = []
    }

    tags = {
        Environment = "${var.env}"
        Name = "${local.fileManagerLambdaFull}"
        Project = "${var.project}"
    }

    environment {
        variables = {
            CLEAN_BUCKET = "${module.bucket_2.s3_bucket_name}"
        }
    }
}