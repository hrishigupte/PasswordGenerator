#Requires -RunAsAdministrator
$SSHInstalled = Get-WindowsCapability -Online | ? Name -like 'OpenSSH.Client*' | %{$_.State}
if ($SSHInstalled.ToString().Trim().ToLower() -ne "installed")
{
    Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
    $SSHInstalled = Get-WindowsCapability -Online | ? Name -like 'OpenSSH.Client*' | %{$_.State}
    if ($SSHInstalled.ToString().Trim().ToLower() -ne "installed")
    {
        echo "File Encryption is not available at this time as OpenSSH Client is not installed and your system failed to install the client...Client is required to generate keys"
        exit
    }
}
else {
    echo "OpenSSH is already installed on System"
    exit
}