# Terraform
Example for Hashicorp Terraform usage on vSphere

# Usage on Windows

## Clone this repository

## Prerequisites ##

All prerequisites are installed with the help of **Chocolatey**, to install **Chocolatey** excute the following commands:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
ku
```

**Terraform** (to be able to use terraform...):

```powershell
choco install terraform
```

**Vault** (to be able to test Vault, not needed for **Terraform** to work though...):

```powershell
choco install vault
```

**VMware Workstation Player** (needed for VMware driver):

```powershell
choco install vmware-workstation-player
```

**Set your environement**

Set proxy env vars:

```powershell
$env:HTTP_PROXY="http://user:password@proxy.domain:8080"
$env:HTTPS_PROXY="http://user:password@proxy.domain:8080"
```

Define **Vault** variables as env variables (yes, you need Hasicorp Vault!):

```powershell
$url='https://vault.domain/v1/auth/approle/login'
$form= @{
    role_id = '6c5855b6-b188-8666-ac43-3f2145517c37'
    secret_id = '895ee8e3-a17f-964b-7780-07035d2dd8a5'
    }

$response=Invoke-RestMethod -Uri $url -Method Post -Body $form | Select-Object -Property auth
$token=($response[0].auth | Select-Object client_token | ft -HideTableHeaders | Out-String).Trim()
$env:VAULT_TOKEN=$token
$env:VAULT_ADDR="https://vault.domain"
$env:VAULT_SKIP_VERIFY="true"
```

## Move to the directory containing the cloned project
```powershell
cd C:\my_cloned_projects\terraform
```

## Initialize Terraform
It will check provider plugins are present and up-to-date:
```powershell
terraform init
```

## Plan Terraform
It will compare the current status of the infrastructure vs the desired state (in main.tf file):
```powershell
terraform plan
```

## Apply Terraform
It will apply changes (add/change/destroy resources):
```powershell
terraform apply -auto-approve
```

## Check
It will take some time, but you will find a new VM "terraform-test" in the vcenter.

## Play around!
Try to change some parameters (num_cpus,...) and see how terraform react when you replay Plan and Apply.
