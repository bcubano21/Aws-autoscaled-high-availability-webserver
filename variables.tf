variable "userdata" {
  default = <<-EOF
  #!/bin/bash
  sudo yum - y update
  sudo yum install -y httpd
  sudo service httpd start
  echo '<!doctype html><html><head><title>Example Terraform Web Server Deployment</title><style>body {background-color: #1c87c9;}</style></head><body></body></html>' | sudo tee /var/www/html/index.html
  echo "<BR><BR>Terraform autoscaled app multi-zone<BR><BR>" >> /var/www/html/index.html
  EOF
}