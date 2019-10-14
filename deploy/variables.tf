variable "name_prefix" {
    default = "bucketdemo"
}

variable "region" {
    default = "us-east-2"
}

variable "env" {
    default = "dev"
}

variable "project" {
    default = "bucketdemo"
}

variable "lambda_runtime" {
    default = "nodejs10.x"
}

variable "lambda_memory_size" {
    default = "1024"
}

variable "lambda_timeout" {
    default = "120"
}

variable "bucket_1_name" {
    default = "upload-dirty"
}

variable "bucket_2_name" {
    default = "upload-clean"
}

variable "bucket_notification_extensions" {
    description = "List of accepted file extensions for the buckets"
    type = set(string)
    default = [".mp4", ".mov"]
}

variable "bucket_notification_events" {
    default = ["s3:ObjectCreated:*"]
}

variable s3_cors_allowed_methods {
    default = []
}

variable "s3_cors_allowed_origins" {
    default = []
}