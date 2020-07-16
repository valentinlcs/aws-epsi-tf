terraform {
    backend "s3" {
        bucket = "epsi-valentinlcs"
        key = "epsi/terraform.fstate"
        region = "us-east-1"
    }
}