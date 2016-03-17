# Refresh all VM's
 
param (
    [string]$server = $(Throw "parameter 'server' is required!"),
    [string]$username,
    [string]$password
)
 
# Connect to the specified server
If ($username -eq "") {
    # Connect to server without username & password
    Connect-VIServer -Server $server
}
ElseIf ($username -ne "" -and $password -eq "") {
    # Connect to server with username only
    Connect-VIServer -Server $server -User $username
}
Else{
    # Connect to server with username & password
    Connect-VIServer -Server $server -User $username -Password $password
}
 
# Get all VM's, excluding templates
$vms = Get-View -ViewType VirtualMachine -Property Name -Filter @{"Config.Template"="false"}
foreach($vm in $vms){
    $vm.reload()
}