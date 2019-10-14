provider "aws" {
    region = "${var.region}"
    version = "2.12"
}

locals {
    lambdaPackageName = "lambdas"
}

data "aws_caller_identity" "current" {}

data "aws_vpc" "vpc" {
    filter {
        name = "tag:Name"
        values = ["vpc"]
    }
}

