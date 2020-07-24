# CONVEX

Cloud Open-source Network Vulnerability Exploitation eXperience (CONVEX) spins up Capture The Flag environments in your Azure tenant for participants to play through. The CTFs themselves are organized into independent modules that contain a create and teardown script to setup the environment programmatically. Modules also include a walkthough for each module, in case participants get stuck.

---

## Getting Started

### Prerequisites
 - There are two identities to keep in mind when deploying, the administrator and the participant(s).
   - The administrator identity is the one running convex.ps1 and deploying the modules. They must have sufficient permissions to create resources, groups, users, and service principals. The administrator is also responsible for giving participants their login credentials.
   - The participant(s) identities are the ones playing the CTFs. They have their identites provisioned to them by the administrator.
 - An empty Azure tenant with two subscriptions. Do **NOT** run CTF exercises in a production environment. Modules use start and end subscriptions, where start refers to where participants begin and end refers to where the flag is located.
 - Install [Stormspotter](https://github.com/Azure/Stormspotter/). Stormspotter is an open-source tool from Azure Red Team used to create an attack graph of Azure subscriptions.
 
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
    - The script will begin by having you sign in to Azure for both the Az Powershell Modules as well as Azure CLI. It is important to sign in with the same identity both times and that the identity has the appropriate levels of access.
    - convex.ps1 is the script to both create and teardown modules, enter which operation you are trying to complete for this invokation of the script. Multiple calls to this script will be necessary to create and teardown.
    - The amount of users that are created is per module. I.e. inputting 5 users and creating modules 1, 2, and 3 simultaneously will create 15 users, 5 for each module.
    
 3. Allow the resources to deploy.
 
 ## Playing the CTFs
 ### Administrators
 Administrators will have the responsibility of giving participants their participant account and password. The username can be found either in Azure Active Directory or in the User Key Vault found in the Resource Group of the starting subscription for each module. The User Key Vault also contains the user's password.
 
 ### Participants
 Participants will receive their username and password from the administrator. They can then log on to the [Azure portal](https://portal.azure.com) with those credentials to enter the CTF environment and begin.
 
 ## Notes
 - Everytime convex.ps1 is run, it will either create or teardown modules, but not both. It can, however, create or teardown multiple modules with one call.
 - Tearing down a module will delete the environment as well as removing the participant accounts and that module's specific security group from the Azure tenant. 
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
