#Tecnics specific vars
param (
  [string]$registry_path = "HKLM\SOFTWARE\TecMFA\TecMFACredProvider\UTM",
  [string]$baseou = "DC=acme,DC=loc",
  [string]$groupname = "local",
  [string]$groupou
)

<##########################################################################
Current Status: Test code
TODO
- DONE: Work on delta records matching. They are not currently in the same format.
- DONE: Implement the registry modification methods
- DONE: Pull in variables from command line arguments
- DONE: Pull users from AD group membership
- Implement debugging option
- Implement flag to record all record changes to event log

###########################################################################>


<##########################################################################

This section of code is establishing the possible function calls

###########################################################################>


Function Write-Event
  {
    param(
      [parameter(mandatory)]
        [string]$message,
        [int]$id
        )
    Write-EventLog -LogName "Application" -Source "Application" -EventId $id -EntryType Information -Message $message -Category 1
}

Function Test-RegKeyExists
  {
    param(
      [parameter(mandatory)]
        [string]$regkey
        )
    return test-path Registry::$regkey    
}

Function Get-CurrentRegistryRecords
  {
   $recordlist = @()
   $recordlist += get-childitem -path Registry::$registry_path -Name
   return $recordlist
}

Function Get-CurrentListOfUsers
  {
    if ($groupou.Length -eq 0)
      {
        $groupou = Get-DistinguishedName
      }
 
    $root = [ADSI]"LDAP://$baseou"
    $search = [adsisearcher]"(&(objectcategory=user)(memberof=$groupou))"
    $search.SearchRoot = $root
    $search.SizeLimit = 3000
    $results = $search.FindAll()

    $report =@()
    foreach($result in $results){$report += $result.properties | select @{N='Name'; E={$_.name}}, @{N='SamAccount'; E={$_.samaccountname}}, @{N='UPN'; E={ ($_.userprincipalname)}}}
    return $report
}

Function Get-DistinguishedName
  {
    $root = [ADSI]"LDAP://$baseou"
    $search = [adsisearcher]"(&(objectcategory=group)(cn=$groupname))"
    $search.SearchRoot = $root
    $search.SizeLimit = 1
    $result = $search.FindAll()
    
    $dn = $result.properties.distinguishedname
    
    if ($dn -eq $null)
      {
        write-host "Can't find security group $groupname"
        write-event -message "Security Group $groupname could not be found" -id 4009
        exit
      }
    else
      {
        return $dn
      }
}

Function Add-UserTransformation
  {
    param(
      [parameter(mandatory)]
        [string]$upn,
        [string]$samaccount
    )
    
    new-item -path registry::$registry_path -name $samaccount
    new-itemproperty -path registry::$registry_path\$samaccount -name "TransformedUsername" -value $upn
}

Function Remove-UserTransformation
  {
    param(
      [parameter(mandatory)]
        [string]$samaccount
    )
    remove-item -path registry::$registry_path\$samaccount
}

<##########################################################################

This is the start of the program execution

###########################################################################>

write-event -message "Starting the Tecnics user account transformation list build" -id 4005

if((Test-RegKeyExists -regkey $registry_path))
  {
    $currentlist = Get-CurrentRegistryRecords
    $newlist = Get-CurrentListOfUsers

    #Remove these users
    $remuser = $currentlist | where {$newlist.SamAccount -notcontains $_}
    #Add these users
    $adduser = $newlist.SamAccount | where {$currentlist -notcontains $_}

    foreach($user in $remuser)
      {
        Remove-UserTransformation $user
        Write-Output "Remove this user $user"
    }

    foreach($user in $newlist)
      {
        if($adduser -contains $user.SamAccount){
          add-usertransformation -upn $user.UPN -samaccount $user.samaccount
          Write-Output "Add this user $user"
        }
    }
}
else
{
  Write-Output "Registry key $registry_path does not exist"
  Write-Output "You must install the Tecnics management application prior to this script executing"
  }

write-event -message "Tecnics user account transformation list build has finished" -id 4006
