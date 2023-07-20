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

    - Create a new resource for the ec2 instance

      ```
        resource "aws_instance" "nemo_dev_node" {
            instance_type = "t3.micro"
            ami = data.aws_ami.server_ami.id
            key_name = aws_key_pair.nemo_keypair_auth.id
            vpc_security_group_ids = [aws_security_group.nemo_security_group.id]
            subnet_id = aws_subnet.nemo_subnet.id

            root_block_device {
            volume_size = 10
            }

            tags = {
                Name = "dev-node"
            }
      }
      ```

    - Now before applying changes we need to wait for the next step and add some user data to this instance...

18. We are going to utilize userData to bootstrap our instance and install docker engine. This will allow us to have EC2 instance deployed with Docker ready to go for out dev needs

    - First we create a userdata.tpl file with following code in it :

      ```
          #!/bin/bash
          sudo apt-get update -y &&
          sudo apt-get install -y \
          apt-transport-https \
          ca-certificates \
          curl \
          gnupg-agent \
          software-properties-common &&
          curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &&
          sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" &&
          sudo apt-get update -y &&
          sudo sudo apt-get install docker-ce docker-ce-cli containerd.io -y &&
          sudo usermod -aG docker ubuntu
      ```

    - Now lets go to main.tf and add this userdata to our resource inside aws_instance `user_data = file("userdata.tpl")`...

    - You can now run `terraform apply` and later check in the AWS Console in the EC2 Console that you have really launched a instance

19. Now let's SSH into the instance

    - First we need the IP adress either from EC2 Console or the terraform show state script

    - Then we run `ssh -i ~/.ssh/nemokey ubuntu@13.49.74.26` - where the numbers are the IP Adress and change the path to your own ssh key and like that you are in the EC2 instance

    - You can test this by running docker --version and see that you really are in there and that you actually have docker installed

20. SSH Config Scripts - lets configure VSCode to connect to EC2 Instance

    - Go to extensions and search for SSH (Remote - SSH by Microsoft) and install it

    - We are going to use template files to create configuration scripts

    - Create the file windows-ssh-config.tpl with following :
      ```
      add-content -path c:/users/neman/.ssh/config -value @'
      Host ${hostname}
          HostName ${hostname}
          User ${user}
          IdentityFile ${identityfile}
      '@
      ```

21. Now we are going to utilize Provisioner to config VSCode to be able to ssh into the EC2 Instance `https://developer.hashicorp.com/terraform/language/resources/provisioners/syntax`

    - Add this code inside the main.tf inside the ec2 instance at the very bottom

      ```
      provisioner "local-exec" {
          command = templatefile("windows-ssh-config.tpl", {
              hostname = self.public_ip,
              user = "ubuntu",
              identityfile = "~/.ssh/nemokey"
          })
          interpreter = [ "Powershell", "-Command" ]
      }
      ```

    - This will create our instance and replace hostname, user and identityfile with our stuff

22. Terraform Apply - replace

    - Now we are going to redeploy EC2 instance with our privisioner and our config

    - By running `terraform apply -replace aws_instance.nemo_dev_node` rename to your instance name inside main.tf it will show the changes and that you have 1 instance to destroy and 1 to create, and you will type "yes" when prompted

    - By running `cat ~/.ssh/config` you can see if the config with hostname, user and identityfile is created

23. Now, time for the truth, can we remote ssh with VSCode

    - Go to View > Command palette and write SSH and go to `Remote-SSH: Connect to Host...`

    - Choose the IP and it should open up a new VSCode that will prompt you to choose platform, and you should choose Linux and Continue, open up a terminal and you should see ubuntu@ip_adress. Congratulations !

    - You can even choose to open a folder and open the /home/ubuntu and you are on a fully remote terminal with all the files at hand...

24. Now we will start optimizing our scripts with variables in Terraform... `https://developer.hashicorp.com/terraform/language/values/variables`

    - We will start by changing the name of the OS in the provisioner to a variable instead so "windows" -> ${var.host_os}

    - Next we create variables.tf file where we keep our variables, so add this to it

      ```
      variable "host_os" {
          type = string
      }
      ```

    - Next we do something crazy and that is that we destroy our infrascture with `terraform destroy` and you will see that it is asks us to declare a variable, so we will find a way to declare it other way but for now we can declare dynamically

    - If we now run `terraform plan` it will asks us again to declare the variable

25. Variable Precedence

    - You can use `terraform console` to check the value of a variable but it says knows after apply

    - Now we add default value to the host_os variable `default = "windows"`
    - Now if we run console it says windows

    - Now we create a new file named `terraform.tfvars` and give the value of host_os of `linux`. If you run the console now you will see that the `.tfvars` takes presedence over the default value in `variables.tf` file
    - If you want to override everything that you did with a declaration and value of the variable you can do it inline with a command for example `terraform console -var="host_os=unix"` and you will now get `unix` as you host_os everywhere

26. Conditionals, we are going to change the interpeter inside the ec2 instance inside main.tf `https://developer.hashicorp.com/terraform/language/expressions/conditionals`

    - simple commande inline just `interpreter = var.host_os == "windows" ? ["Powershell", "-Command"] : ["bash", "-c"]`

    - Now we are going to run `terraform apply` again, do deploy and see if we can SSH into it through VSCode...

    - You can checkout the EC2 instance IP adress and connect to it through VSCode, it should work same as the last time...

27. Outputs `https://developer.hashicorp.com/terraform/language/values/outputs`

    - Create `outputs.tf` file and add

      ```
      output "dev_ip" {
          value = aws_instance.nemo_dev_node.public_ip
      }
      ```

    - now run `terraform apply -refresh-only` and that will just add output and you can later just run `terraform output` and see the value

### All finished, now you can get creative !
