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
