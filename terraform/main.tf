name: Deploy Medusa EC2 Instance

on:
  push:
    branches:
      - master

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v2

      - name: Set up AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Install Terraform
        run: |
          sudo apt-get update
          sudo apt-get install -y wget unzip
          wget https://releases.hashicorp.com/terraform/1.3.6/terraform_1.3.6_linux_amd64.zip
          sudo rm -f /usr/local/bin/terraform  # Remove existing binary if it exists
          unzip terraform_1.3.6_linux_amd64.zip
          sudo mv terraform /usr/local/bin/
          terraform -version

      - name: Initialize Terraform
        run: |
          cd medusa-store/terraform
          terraform init

      - name: Apply Terraform configuration
        run: |
          cd medusa-store/terraform
          terraform apply -auto-approve

      - name: Retrieve EC2 Instance IP
        run: |
          echo "Instance IP: $(terraform output -raw instance_ip)"

