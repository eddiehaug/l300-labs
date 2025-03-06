# Terraform Lab Instructions

1. Start the lab and get the variables (all the values in yellow)
2. Modify variables.tf and backend.tf with the values from the lab
3. SSH into the machine
4. Use the following code to install Terraform:

```
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```
5. Upload the files
6. Create the directory: `mkdir cepf-iac`
7. Move the files into the directory: `mv main.tf variables.tf outputs.tf bakend.tf cepf-iac`
8. Initialize Terraform: `terraform init`
9. Check the plan: `terraform plan`
10. Commit the changes: `terraform apply`
11. Get the IP address from the output (last line) and check whether it works
12. Validate the lab



# Identity Federation Lab Instructions

## Task 1

1. In the GCP Console, go to Managed Microsoft AD and Set the password

Make a note of

* domain
* password
* NetBIOS name

2. Open the Workspace Admin and verify the primary domain following the instructions in the lab

3. In Workspace Admin, go to domains and add the domain from step 1 as a secondary domain.  

* Go to Cloud DNS, select the zone name with the description cepf-zone and add the TXT record to verify the domain

4. Go to compute engine and reset the password of the AD VM, and make a note of it.

* Click on RDS and download the RDS Setup File to your computer to configure a local RDS (recommended).  Alternatively, open Remote Desktop from within the VM provided by the lab.

* Create a new connection using the information from Step 1


6. Install GCDS using the command in the lab

7. Run GCDS

**GCDS Configuration**

1. Google Domain Configuration:

* Primary Domain from Workspace Admin
* Username and password for Workspace from the lab
* Continue > Allow


2. LDAP configuration

* Standard LDAP
* Host name:  the domain from step 1
* Port 389
* Authorized user: NETBIOS_NAME_FROM_STEP_1\setupadmin
* Password: From Step 1
* Base DN: DC=NETBIOS_NAME_FROM_STEP_1,DC=cepf,DC=cymbal,DC=net


3. User Accounts:

User attributes: Default
Additional user attributes: Default
Search Rules: Default

4. Groups.  Use defaults

5. Sync: 

1. Simulate Sync
2. Sync and apply changes



**End of Task 1**



## Task 2


In order to complete task 2, just follow the steps here: https://cloud.google.com/architecture/identity/federating-gcp-with-active-directory-configuring-single-sign-on

The ADFS url that you can enter into the different fields is the URL from Step 1 in Task 1, from managed AD.



**NOTE:** If you used a local RDS client, you can simply copy the certificate that you'll have to export to your machine, and import it from there.
