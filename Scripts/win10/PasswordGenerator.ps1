$EncryptorCommand = "Encryptor.exe"
$outputFile
$pGenPrivateKeyFile = "pGenKeyFile.pem"
$pGenPublicKeyFile = "pGenKeyFile.pub"
$defaultPersonalPath=[System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Personal)
$defaultPGenDataPath = "$defaultPersonalPath\pGenData\"
$sshPath = "~\.ssh\"
$sshPath = Resolve-Path -Path $sshPath |Foreach-Object{$_.Path}

$PasswordGenerator = "..\..\bin\Release\net5.0\win10-x64\publish\PasswordGenerator.exe"
Stop-Transcript -ErrorAction SilentlyContinue | Out-Null 

$ReadOrCreateChoice = Read-Host -Prompt " Would you like to view an existing Password or create a new Password (v to View, c to Create)"

if ($ReadOrCreateChoice.Trim().ToLower() -eq "c")
{
    $transcriptOutputFileName = $env:TEMP + "\pgenoutput" + [System.DateTime]::Now.ToShortDateString().ToString().Replace("/","") + [System.DateTime]::Now.ToShortTimeString().ToString().Replace(" ","").Replace(":","") + ".txt"
    Start-Transcript -Path $transcriptOutputFileName -Append -Force
    & $PasswordGenerator 
    Stop-Transcript | Out-Null
    $transcriptOutPut = Get-Content $transcriptOutputFileName 
    foreach ($line in $transcriptOutPut)
    { 
        if ($line.ToString().Contains("Output"))
        {
            $charArray = $line.Split("-")
            $outputPasswordFile = $charArray[1].Trim()
            $outputFile = $outputPasswordFile
        }
    
    }
    $EncryptPassword = Read-Host  -Prompt "Would you like to encrypt the password using Encryptor app after the password is created (recommended)?(yes/no)"

    if ($EncryptPassword.Trim().ToLower() -eq "yes")
    {
        if (!(Get-Command $EncryptorCommand -ErrorAction SilentlyContinue))
        {
            Write-Output "Encryptor is not installed"
            Write-Output "Please install Encryptor to encrypt keys and add to Path on computer and try to encrypt"
            exit
        }
        else 
        {
            Write-Output "Password will be encrypted"
            if (!((Test-Path -Path $sshPath$pGenPrivateKeyFile) -and (Test-Path -Path $sshPath$pGenPublicKeyFile)))
            {
                if (!(Get-Command ssh-keygen -ErrorAction SilentlyContinue))
                {
                    Write-Output "ssh not installed on your system, we will now attempt to install SSH on your system"
                    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `".\InstallOpenSSH.ps1`"" -Verb RunAs; exit
                }
                $pkeypwd = ""
                $pvpwd =""
                while ($pkeypwd.Trim() -eq "")
                {
                    Write-Output "There are no keys available on your systems. Keys are required to encrypt and decrypt password data. You will now be asked for a password to use with the key on your machine"
                    Write-Output "It is critical that you use a password that you can remember as it will be required when new passwords are to be generated/encrypted/decrypted"
                    $pkeypwd = Read-Host -Prompt "Please enter a password for encryption key. Please ensure to remember this password as the key is required to decrypt the password file once encrypted" -AsSecureString
                    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pkeypwd)
                    $pvpwd = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                    if ($pvpwd.Trim() -eq "")
                    {
                        Write-Output "Encryption of file cannot continue without valid password...provide input a valid password"
                    }
                }                
                & ssh-keygen.exe -f "$sshPath$pGenPrivateKeyFile" -P $pvpwd

                & ssh-keygen -f "$sshPath$pGenPrivateKeyFile.pub" -e -m PKCS8 > $sshPath$pGenPublicKeyFile

                Remove-Item -Path "$sshPath$pGenPrivateKeyFile.pub" -ErrorAction SilentlyContinue
            }
            $ReadPasswordFile = Read-Host -Prompt "The unencrypted password File will now be removed, do you want to view the password that was generated (yes/no)"
            if ($ReadPasswordFile.Trim().ToLower() -eq "yes")
            {
                Get-Content -Path $outputPasswordFile | ForEach-Object{$_}
            }
            Read-Host "Press [ENTER] to proceed with encryption of file....."
            
            Start-Process $EncryptorCommand -ArgumentList "--e --k $sshPath$pGenPublicKeyFile --i $outputPasswordFile --o $outputPasswordFile.enc"
            
            $RemoveUnEncryptedFile = Read-Host -Prompt "Do you want to remove UnEncryptedFile?(yes/no)"
            if ($RemoveUnEncryptedFile.Trim().ToLower() -eq "yes")
            {
                Remove-Item -Path $outputPasswordFile
            }
        }
    }
}

if ($ReadOrCreateChoice.Trim().ToLower() -eq "v")
{
    Write-Output "All password files are stored in $defaultPGenDataPath"
    Write-Output "Program will list all encrypted files so that selected file can be decrypted and displayed" 
    Write-Output "------------------------------------------------------------------------------------------"
    [string[]] $files
    foreach ($item in Get-ChildItem $defaultPGenDataPath -Filter "*.enc")
    {
        Write-Output $item.Name.Split(".")[0]
    }
    $FileToDecryptAndDisplay = Read-Host -Prompt "Enter the password you would like to view: "
    
    if (Test-Path -Path "$defaultPGenDataPath$FileToDecryptAndDisplay*.base64")
    {
        $FileToDecrypt = Get-ChildItem "$defaultPGenDataPath$FileToDecryptAndDisplay*.base64" | Select-Object -First 1
        if ($null -ne $FileToDecrypt)
        {
            $InputFileToDecrypt = $FileToDecrypt.Name
            $OutDecryptedFile = $InputFileToDecrypt.Replace(".enc.base64","")
            $pvkeypwd = Read-Host -Prompt "Please enter password to decrypt private key.. This is the same password which was used when generating password and key was created for the first time" -AsSecureString
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pvkeypwd)
            $pvpwd = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            Start-Process $EncryptorCommand -ArgumentList "--d --k $sshPath$pGenPrivateKeyFile --base64 --privatekeypassword $pvpwd --i $defaultPGenDataPath$InputFileToDecrypt --o $defaultPGenDataPath$OutDecryptedFile" -NoNewWindow -Wait
            if (Test-Path -Path $defaultPGenDataPath$OutDecryptedFile)
            {
                Write-Output "Successfully Decrypted password"
                Write-Output "Password for $FileToDecryptAndDisplay"
                Get-Content $defaultPGenDataPath$OutDecryptedFile
                Write-Output "Decrypted File will now be deleted to protect password"
                Remove-Item -Path $defaultPGenDataPath$OutDecryptedFile -Force
            }
            Read-Host "Press [ENTER] to exit"
        }
    }
}

