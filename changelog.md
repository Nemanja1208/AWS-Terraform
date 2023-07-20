### Documentation source - `https://www.youtube.com/watch?v=iRaai1IBlB0`

# Implementation steps

1. Create a new user in `AWS IAM` with `access key` - programmatic access (can be created after you create a user, just go to user / security credentials)

   - Attach policies directly - `AdministratorAccess`
   - Create user and download csv with credentials

2. In the VS Code install AWS Toolkit extension and go to View > Command Palette and write AWS: Create Credentials Profile

   - Here you can add a profile with custom Name and paste in the credentials you downloaded in the csv file...

   - Now you can go to AWS icon in the left most toolbar and click Connect to AWS...

3. Go to the Extensions again and install `Terraform`, I went with HashiCorp Original one

4. Let's create a working directory now, set up whereever you like...

5. Open that in vsCode and let's gooo !

6. AWS Provider and Terraform Init

   docs : `https://registry.terraform.io/providers/hashicorp/aws/latest/docs`

   - Create a file named `providers.tf` and paste the following code, check the docs for the right version

     ```
     terraform {
      required_providers {
          aws = {
          source  = "hashicorp/aws"
          version = "~> 5.0"
          }
      }
     }
     ```

   - Now we need to add provider block that access aws specifically, should look like this

     ```
     provider "aws" {
         shared_config_files      = ["~/.aws/conf"]
         shared_credentials_files = [~/.aws/credentials"]
         profile                  = "nemoPrivateVSCode"
     }
     ```

   - Now let's run a terraform INIT to initialize and connect to AWS to see if everything checks out...

   - If you need to install terraform as me, follow these instructions here -> `https://developer.hashicorp.com/terraform/downloads`

   - When you successfully initialized terraform you should get a .terraform folder as well as a lock file

7. Deploy the VPC
   docs - `https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc`

   - Create a `main.tf` file inside root map

   - Create a vpc resource by adding this code to main.tf file

     ```
     resource "aws_vpc" "nemo_vpc" {
         cidr_block = "10.123.0.0/16"
         enable_dns_hostnames = true
         enable_dns_support = true

         tags = {
             Name = "dev"
         }
     }
     ```

   - Next run `terraform plan` This shows you what we are trying to build and pieces that are going to be created inside vpc resource

   - Next we run `terraform apply` which is going to create the vpc resource that you can confirm if you check AWS icon in the toolbar on the left in the VSCode and check Resources

8. Now we take a break from building and are looking into the Terraform State `https://developer.hashicorp.com/terraform/language/state`

   - You can access state by running `terraform state list` and terraform state show `[resource name]`
   - If you want to show entire state you can run `terraform show`

9. Terraform Destroy (destroys anything we destroyed) `https://developer.hashicorp.com/terraform/cli/commands/destroy` usefull command but we will not use it now

10. Deploying Subnets and referencing other Resources `https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet`

    - Adding a resource that is subnet into the main.tf - should look something like this

      ```
      resource "aws_subnet" "nemo_public_subnet" {
        vpc_id = aws_vpc.nemo_vpc.id
        cidr_block = "10.123.1.0/24"
        map_public_ip_on_launch = true
        availability_zone = "eu-north-1a"

        tags = {
        Name: "dev-public"
        }
      }
      ```

    - Now run `terraform apply` to add this resource

11. Give our resources way to the internet by using Internet gateway `https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway`

    - adding internet gateway resource with this code in main.tf

      ```
      resource "aws_internet_gateway" "nemo_internet_gateway" {
          vpc_id = aws_vpc.nemo_vpc.id

          tags = {
              Name = "dev-internet-gateway"
          }
      }
      ```

    - running `terraform fmt`- will fix and format correctly

    - Now let's deploy this Internet Gateway resource with `terraform apply`

12. Now we create a A Route Table so we can direct traffic from our subnet to Internet Gateway `https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table`

    - Add these resources to your main.tf

      ```
      resource "aws_route_table" "nemo_public_route_table" {
          vpc_id = aws_vpc.nemo_vpc.id

          tags = {
              Name = "dev-public-route-table"
          }
      }

      resource "aws_route" "default_route" {
          route_table_id = aws_route_table.nemo_public_route_table.id
          destination_cidr_block = "0.0.0.0/0"
          gateway_id = aws_internet_gateway.nemo_internet_gateway.id
      }
      ```

    - Now run `terraform apply` to add this resources

13. Now we create Route Table Association to bridge the gap between route table and subnet `https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association`

    - Register a new resource that is Route Table Association by adding this code in the main.tf

      ```
      resource "aws_route_table_association" "nemo_public_association" {
      subnet_id      = aws_subnet.nemo_public_subnet.id
      route_table_id = aws_route_table.nemo_public_route_table.id
      }
      ```

    - Now we run `terraform apply` to add this resource
    - To checkout all the resource you can always do that in the AWS Console as well when you visit the VPC Console

14. Now we are adding an importent resource to our deployment and that is Security Groups `https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group`

    - Adding the resource in the main.tf with the following code :

      ```
      resource "aws_security_group" "nemo_security_group" {
          name        = "dev_securitygroup"
          description = "dev security group"
          vpc_id      = aws_vpc.nemo_vpc.id

          ingress {
              from_port   = 0
              to_port     = 0
              protocol    = "-1"
              cidr_blocks = ["0.0.0.0/0"]
          }

          egress {
              from_port   = 0
              to_port     = 0
              protocol    = "-1"
              cidr_blocks = ["0.0.0.0/0"]
          }
      }
      ```

    - Now run `terraform apply` to add this resource

15. Before we deploy we need to register a AMI data resource from which we want to deploy `https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ami`

    - Go to EC2 in AWS Console and while "fake" launching a EC2 instance with ubuntu with server 18.04 just copy the AMI ID, that will look something like `ami-074251216af698218` then cancel and go back to EC2 Console and click on IAM under Images and enter that AMI ID and copy the owner ID that is shown. Would be something like `099720109477`.

    - Now we create a new file that we name `datasources.tf` in the root folder and add the following :

      ```
      data "aws_ami" "server_ami" {
          most_recent = true
          owners = ["099720109477"]
          filter {
            name = "name"
            values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
          }
      }
      ```

    - Now lets apply this with `terraform apply`

16. Now we create a Key Pair so that we can use that to ssh into a EC2 instance later `https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair`

    - run this in order to create a key pair `ssh-keygen -t ed25519` and remember where it saves it... Should be C:/Users/[Name]/.ssh

    - now add this code to main.tf but ofc with your paths and names
      ```
      resource "aws_key_pair" "nemo_keypair_auth" {
          key_name = "nemo-key"
          public_key = file("C:/Users/neman/.ssh/nemokey.pub")
      }
      ```
    - Now lets apply this with `terraform apply`

17. Now we are finally deploying our EC2 instance `https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance`
