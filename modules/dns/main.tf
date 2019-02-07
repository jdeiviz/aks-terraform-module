data "azurerm_dns_zone" "dns_zone" {
  name                = "${var.dns_zone_name}"
  resource_group_name = "${var.dns_zone_resource_group}"
}

output "dns_zone_id" {
  value = "${data.azurerm_dns_zone.test.id}"
}

resource "azurerm_dns_a_record" "root_domain" {
  name                = "@"
  zone_name           = "${azurerm_dns_zone.dns_zone.name}"
  resource_group_name = "${azurerm_resource_group.dns_zone.name}"
  ttl                 = 3600
  records             = ["${var.public_ingress_lb_ip}"]
}

resource "azurerm_dns_a_record" "wildcard_domain" {
  name                = "${var.domain == "@" ? "*" : "*.${var.domain}"}"
  zone_name           = "${azurerm_dns_zone.dns_zone.name}"
  resource_group_name = "${azurerm_resource_group.dns_zone.name}"
  ttl                 = 3600
  records             = ["${var.private_ingress_lb_ip}"]
}
