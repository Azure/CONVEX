# CONVEX

Cloud Open-source Network Vulnerability Exploitation eXperience (CONVEX) spins up Capture The Flag environments in your Azure tenant for participants to play through. The CTFs themselves are organized into independent modules that contain a create and teardown script to setup the environment programmatically. Modules also include a walkthough for each module, in case participants get stuck.

---

## Getting Started

### Prerequisites
- The installation and running should be done with PowerShell running as Administrator. In addition, in order to run the script, the `ExecutionPolicy` must be set to `Unrestricted`. To change this, you can run this command
   ```
   Set-ExecutionPolicy Unrestricted
   ```
- [Azure PowerShell](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-4.4.0) modules installed. It is important to have Azure and not AzureRM or both because AzureRM creates conflicts with the new Azure PowerShell Module.
- [Azure Active Directory Module](https://docs.microsoft.com/en-us/powershell/azure/active-directory/install-adv2?view=azureadps-2.0) installed.
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest&tabs=azure-powershell) installed.
- [Azure Function Core Tools](https://github.com/Azure/azure-functions-core-tools/blob/master/README.md#windows) installed
   - This installation can be completed in two steps from PowerShell, first installing Chocolatey and then Azure Function Core Tools through Chocolatey. These installations must be done from an *administrative shell*.
   ```
   [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
   choco install azure-functions-core-tools-3
   ```
- [Stormspotter](https://github.com/Azure/Stormspotter/) installed. Stormspotter is an open-source tool from Azure Red Team used to create an attack graph of Azure subscriptions.
- An empty Azure tenant with at least two subscriptions. Do **NOT** run CTF exercises in a production environment. Modules use start and end subscriptions, where start refers to where participants begin and end refers to where the flag is located.

### Identities Involved
- There are two identities to keep in mind when deploying, the administrator and the participant(s).
   - The administrator identity is the one running convex.ps1 and deploying the modules. They must have sufficient permissions to create resources, groups, users, and service principals. The administrator is also responsible for giving participants their login credentials.
   - The participant(s) identities are the ones playing the CTFs. They have their identites provisioned to them by the administrator.

 
 ## Running CONVEX
 1. Clone the CONVEX Repo
    ```
    git clone https://github.com/Azure/CONVEX.git
    ```
 2. Run convex.ps1
    ```
    cd CONVEX
    .\convex.ps1
    ```
    - The script will begin by having you sign in to the Azure and AzureAD PowerShell modules as well as Azure CLI. It is important to sign in with the same identity and that the identity has the appropriate levels of access.
    - convex.ps1 handles both creating and tearing down the modules, it is the only script you as a user need to call. It will create/teardown all available modules.
    - The amount of users that are created is per module. I.e. inputting 5 users and creating modules 1, 2, and 3 simultaneously will create 15 users, 5 for each module.
    
 3. Allow the resources to deploy.
 
 ## Playing the CTFs
 ### Administrators
 Administrators will have the responsibility of giving participants their participant account and password. The username can be found either in Azure Active Directory or in the User Key Vault found in the Resource Group of the starting subscription for each module. The User Key Vault also contains the user's password.
 
 ### Participants
 Participants will receive their username and password from the administrator. They can then log on to the [Azure portal](https://portal.azure.com) with those credentials to enter the CTF environment and begin.
 
 ## Notes
 Tearing down a module will delete the environment as well as removing the participant accounts and that module's specific security group from the Azure tenant. 

 ---
# Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
