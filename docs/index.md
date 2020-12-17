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

![AzureStorage](/dcos/assets/4_AzureStorageCon)

Once connected, expand the Storage Accounts group, the display name you chose, and Blob Containers. From there, select the Blob beginning with m1 and you can download the flag for Module One.

![StorageExp](/dcos/assets/5_storageExplorer)

### Module 2

### Module 3
