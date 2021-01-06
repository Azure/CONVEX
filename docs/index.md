## CTF Writeup and Solutions

### Module 1

After logging into the [Azure Portal](http://portal.azure.com/) all resources can be listed to gain a better idea as to what this account has access to.

![All Resources](/dcos/assets/1_allresources)

Here, you should see a Key Vault and a Storage Account. While you do not have access to read any container in the Storage Account, you do have access to the Key Vault.  These permissions can be found under the Access Control (IAM) tab on each resource.

![KeyvaultRole](/dcos/assets/2_keyvaultrole)

The primary purpose of Key Vaults is to store secrets, so using the reader permissions on the account you can view all of the keys, secrets, and certificates stored in the vault.

![Keyvault](/dcos/assets/3_keyvault)

Once you have navigated to the secret’s page, you can see the hidden secret value at the bottom of the page. You then view the hidden value and copy it directly to your clipboard.
Since the only other resource in this subscription is a storage account, and the title of this key is SAkey1 we can assume this is the credential needed to access the storage account.
[Microsoft Azure Storage Explorer](https://azure.microsoft.com/en-us/features/storage-explorer/) allows you to connect a Storage Account using only the name of a Storage Account as well as one of its two keys. 
Fill out Azure Storage Explorer's connection wizard (Display name can be anything you want) using the name, which you can copy directly from the Azure portal, and the key that you have grabbed from the Key Vault.

![AzureStorage](/docs/assets/4_AzureStorageCon)

Once connected, expand the Storage Accounts group, the display name you chose, and Blob Containers. From there, select the Blob beginning with m1 and you can download the flag for Module One.

![StorageExp](/docs/assets/5_storageExplorer)

### Module 2
This walkthrough assumes that you are now signed in with your module 2 (NOT module 1) participant account in the [Azure portal](http://portal.azure.com/).
The first step is to navigate to All resources either from the landing page, or by opening the left-hand menu and selecting it from the list.
The only resource visible is an App Service beginning with m2. Clicking on that and navigating to the Configuration blade will reveal that “application_id” and “application_key” have been left in Application settings. 

![StorageExp](/docs/assets/6_appconfig)

Clicking on "Advanced edit" enables you to access the configuration values for this service.
This is a great time to enumerate the rest of the tenant using a tool like [StormSpotter](https://github.com/Azure/Stormspotter), an open source ART tool, for scanning. Stormspotter is not required for this module as all information can easily be found using the portal and Az CLI but Tools like this will become an invaluable aid when the target subscriptions become vast and complex.

![Stormspotter](/docs/assets/7_better_stormspotter)

You can now log in to Azure as a service principal using the AppID AppKey found in the previous step.  Service principals are concrete instances created from the application object and inherit certain properties from that application object. This relationship is similar to object oriented programming where the service principal is like an instantiated object while the Application is the class for that object.

```Powershell
$appid = "<App Id found in portal"
$appkey = "App key found in portal"
az login --service-principal -u $appid -p $appkey --tenant "<Tenent ID found on the Azure Active Directory Homepage>"
```

Once authenticated using the Service Principal, listing available resources reveals a Key Vault. 

![list](/docs/assets/8_res)

Listing the secrets shows that it contains another App Key, which we can guess is for the second Application. 

![list_kv](/docs/assets/8_kvs)

Once in the second Service Principal, listing out the available resources shows that we now have a Storage Account that is visible. Using PowerShell, we can list the Storage Account name and the Resource Group to obtain the keys for that Storage Account. 
The Microsoft Azure Storage Explorer allows you to authenticate into a Storage Account with only a name and key, meaning that you could access the containers in a similar fashion to Module One. Alternatively, you could use PowerShell to list out the Storage Account, Container, and Blob contents. Either way will allow you to download the Module Two flag from the Storage Account blob.

![Get Keys](/docs/assets/11_storage2)

Useful Resources:

[Listing out available resources](https://docs.microsoft.com/en-us/powershell/module/az.resources/get-azresource?view=azps-4.4.0)

[Signing in as a service principal](https://docs.microsoft.com/en-us/powershell/azure/authenticate-azureps?view=azps-4.4.0#sign-in-with-a-service-principal-)

[Accessing secret values in a Key Vault](https://docs.microsoft.com/en-us/azure/key-vault/secrets/quick-create-powershell#adding-a-secret-to-key-vault)

[Getting Storage Account Keys](https://docs.microsoft.com/en-us/powershell/module/az.storage/get-azstorageaccountkey?view=azps-4.4.0)

### Module 3
This walkthrough assumes that you are now signed in with your module 3 (NOT module 2) participant account in the [Azure portal](http://portal.azure.com/).
The first step is to navigate to All resources either from the landing page, or by opening the left-hand menu and selecting it from the list.  The only resource visible should be an Application Insights beginning with m3. 

![Get res_app](/docs/assets/12_allresapp)

Click on that, and then navigate to the Search blade and hit Refresh on the Search menu to populate the results. Once the results are populated, find a trace containing “Authentication complete” by looking at the most recent items. The string following is an access token which can be used to authenticate as the m3aadapp* which has access to a Key Vault.

![log](/docs/assets/13_appinsauth)

After exploring the tenent you will find an m3 Key Vault along with its vaultUri. Using the application Postman, you can authenticate directly to the Key Vault using a GET request. The request URL is https://{vaultUri}/secrets?api-version=7.0 and authorizing using a bearer token where the token is the one grabbed from the Application Insights. You could also attempt to enumerate all resources in the subscription with the access token found in Application Insights, but the response would clue you in to the fact that the token is for a Key Vault specifically.

![postman](/docs/assets/14_postman)

That request will return the secrets present in the Key Vault, once you find the secret you want, you can send the request again but with https://{vaultUri}/secrets/{secretName}?api-version=7.0 as the request URL. Since the secret is a name, we can assume the secret value is the password associated with that user. 
Logging in with that account (johndoe@<domain name of participant account>) will reveal a new Storage Account in the Azure portal. Going into the m3resources container will show the flag for the third module.
