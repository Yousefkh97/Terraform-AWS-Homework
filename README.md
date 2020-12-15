# Terraform-AWS-Homework

This repository includes a Terraform Script that creates a VPC 

we created terraform script that launches a load balancer application for my-bitcoin docker image
step 1 : 
 - create the VPC with two subnets 10.0.1.0/24 10.0.2.0/24 
 - creating the routing table SSH,HTTP, HTTPS
 - create a network interface and assign an elastic ip for the interface
 
 step 2 : 
  - launch EC2 instance with the network-interface that we build in step 1
  - we use "user-data" for installing docker.io and pull & run the image from repository shadifadila/my_repo:my-bitcoin
  
 step 3: 
  - create application-load-balancer
  - create & attach the EC2 instance to the ELB-group 
  - configure the ALB network
