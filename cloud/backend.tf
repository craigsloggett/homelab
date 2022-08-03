terraform {
  backend "s3" {
    bucket         = "045638356163-ca-central-1-terraform-state"
    dynamodb_table = "045638356163-ca-central-1-terraform-state-locks"
    encrypt        = "true"
    key            = "terraform.tfstate"
    kms_key_id     = "alias/s3/045638356163-ca-central-1-terraform-state"
    region         = "ca-central-1"
  }
}
