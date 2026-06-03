provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "three-tier-stepfunction"
      ManagedBy   = "terraform"
      Environment = var.environment
    }
  }
}
