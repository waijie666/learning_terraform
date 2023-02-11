terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

provider "cloudflare" {
  api_key = var.api_key
  email   = var.email
}

locals {
  records = [
    { name = "test1", proxied = false, type = "A", value = "10.10.10.10" },
    { name = "test2", proxied = false, type = "A", value = "10.10.10.10" },
    { name = "test3", proxied = false, type = "A", value = "10.10.10.10" }
  ]
}

resource "cloudflare_record" "testing_resource" {
  for_each = { for x in local.records : "${x.name}_${x.type}" => x }
  name     = each.value.name
  proxied  = each.value.proxied
  type     = each.value.type
  value    = each.value.value
  zone_id  = var.zone_id
}
