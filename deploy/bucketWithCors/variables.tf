variable "region" {
    default = "us-east-2"
}

variable "env" {
    default = "dev"
}

variable "project" {
    default = "bucket-demo"
}

variable "s3_bucket_name" {
    default = "bucket1"
}

variable "s3_cors_allowed_methods" {
    default = ["GET"]
}

variable "s3_cors_allowed_origins" {
    default = ["*"]
}

variable "tags" {
    description = "A mapping of tags to assign to the resource"
    default = {
        Environment = "dev"
    }
}

locals {
    accountName = "${var.project}-${var.env}"
}