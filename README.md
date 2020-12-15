# Terraform-AWS-Homework

This repository includes a Terraform Script that launches a load balancer application for my Bitcoin Docker image.

The scripts includes:
 1) A VPC (Virtual Private Cloud), two subnets with all related AWS resources such as routing table, security group, NIC and Elastic IP.
 2) An Ubuntu Instance that is connected with the resources in step 1 which install docker, pull and run the Bitcoin Docker image.
 3) Create Application load balancer and attach the instance we created in step 2 to it.
 
 
How to Run?

First of all make sure that you have terraform downloaded. Then download the main.tf file, at the beginning of the file add this code :

provider "aws" {
  region     = "eu-central-1"
  access_key = "my-access-key"
  secret_key = "my-secret-key"
}
add your access_key and secret_key. Open a new terminal in the current working directory and run "terraform apply" .



Output:

 When the command "terraform apply" terminates you can find two outputs. copy the server_public_ip1 output and try to log in to it with port 5000.
 You should see the Bitcoin page with the current price of Bitcoin in USD.
