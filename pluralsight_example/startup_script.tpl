#! /bin/bash
sudo apt update 
sudo apt install nginx awscli -y
aws s3 cp s3://${s3_bucket_name}/website/index.html /home/ubuntu/index.html
aws s3 cp s3://${s3_bucket_name}/website/Globo_logo_Vert.png /home/ubuntu/Globo_logo_Vert.png
sudo rm /var/www/html/index.html
sudo cp /home/ubuntu/index.html /var/www/html/index.html
sudo cp /home/ubuntu/Globo_logo_Vert.png /var/www/html/Globo_logo_Vert.png
sudo systemctl start ssh