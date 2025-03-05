# Instructions

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
11. Get the IP address from the output (last line)
12. Validate the lab
