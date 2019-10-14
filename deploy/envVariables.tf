terraform {
    backend "s3" {
        bucket = "bucketdemo-support"
        key = "terraform/bucketdemo/dev/terraform.tfstate"
        region = "us-east-2"
    }
}

locals {
    accountName = "${var.project}-${var.env}"
}