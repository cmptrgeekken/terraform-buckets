output "s3_kms_key_id" {
    value = "${aws_kms_key.s3_kms_key.key_id}"
}

output "s3_kms_key_arn" {
    value = "${aws_kms_key.s3_kms_key.arn}"
}

output "s3_iam_policy_arn" {
    value = "${aws_iam_policy.s3_iam_policy.arn}"
}

output "s3_bucket_arn" {
    value = "${aws_s3_bucket.s3_bucket.arn}"
}

output "s3_bucket_name" {
    value = "${aws_s3_bucket.s3_bucket.id}"
}

output "s3_bucket_domain_name" {
    value = "${aws_s3_bucket.s3_bucket.bucket_domain_name}"
}

output "s3_bucket_regional_domain_name" {
    value = "${aws_s3_bucket.s3_bucket.bucket_regional_domain_name}"
}