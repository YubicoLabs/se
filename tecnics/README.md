# Tecnics

## Information in this folder is targeted at supporting the Tecnics tool for Okta deployments



**usernameTranslate.ps1**

*Script Author: Robert Booth*

*SE partner SME: Greg Reynolds*

This is a powershell script to assist in deployments of the Tecnics TecMFA credential provider. It some edge cases the username to login to Okta is different from the Windows shortform login name. Tecnics has updated their tool to help with this translation.
The target goal of this script is to run on a computer startup and can be deployed from a GPO in AD or a local schedule task. It will pull information from LDAP based on a group membership and update the registry for TecMFA.

Default properties can be manually set in the first few lines of the script.
It's suggested that only the __baseou__ variable be hard coded.

__Manually test the script on a single box__

<ol>
<li> Copy the script to the target machine</li>
<li> Open a powershell window with an account that has permission to modify the registry</li>
<li> Execute the following command</li>
  
    usernameTranslate.ps1 -baseou "DC=flex,DC=loc" -groupname "myDomainGroupName"

<li> Review the following registry key to see if group members have been added</li>

    HKLM\SOFTWARE\TecMFA\TecMFACredProvider\UTM

</ol>

> You will need to update the **baseou** to your domain name. Example: **acme.com** would be **"DC=acme,DC=com"**


__NOTE:__

The script also puts an eventlog record in each time it executes with the results. These events are in the Application event log.

