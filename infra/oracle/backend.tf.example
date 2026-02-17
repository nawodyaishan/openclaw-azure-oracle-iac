terraform {
  backend "s3" {
    # Bucket, Key, Region, Endpoint are configured via backend.conf
    # Note: OCI Object Storage allows using the S3 API
    key                         = "terraform.tfstate"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    force_path_style            = true
  }
}
