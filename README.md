# KHM

> Administracija računarskih mreža  
> Projekat 2024/25.
> - Hastor Tarik
> - Kadušić Kanita
> - Mahmutović Mirza

## Project Overview 🧩

This project uses Terraform to provision AWS infrastructure. It sets up a VPC with public and private subnets. The private subnet hosts a MySQL database on an EC2 instance, running in a Docker container. In the public subnet, EC2 instances are launched via an Auto Scaling Group, each running a Dockerized Node.js application behind an Apache2 server. Apache2 handles HTTP to HTTPS redirection and acts as a reverse proxy to the Node.js app.

The infrastructure supports a scalable web application with a secure database backend.

## Links 🔗

- [Node.js Application Image](https://hub.docker.com/repository/docker/kkadusic2/real-estate-sales/general) (Docker Hub repository with the application image)
- [Continuous Deployment](https://github.com/kanitakadusic/real-estate-sales) (GitHub repository containing GitLab CI/CD and AWS ECS setup)
