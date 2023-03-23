#Random ID for unique naming
resource "random_integer" "rand" {
  min = 100000
  max = 999999
}

locals {
  common_tags = {
    company      = var.company
    project      = "${var.company}-${var.project}"
    billing_code = var.billing_code
    deploy       = "terraform"
  }

  s3_bucket_name = lower("globo-web-app-${random_integer.rand.result}")
}
