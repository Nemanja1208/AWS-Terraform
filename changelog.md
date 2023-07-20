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
