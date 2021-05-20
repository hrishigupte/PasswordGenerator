param(
[Parameter(Mandatory=$false)][string]$ApplicationName,
[Parameter(Mandatory=$false)][string]$EncryptPassword
)

$EncryptorCommand = "Encryptor.exe"
$outputFile
$pGenPrivateKeyFile = "pGenKeyFile.pem"
$pGenPublicKeyFile = "pGenKeyFile.pub"
$sshPath = "~\.ssh\"
$sshPath = Resolve-Path -Path $sshPath |%{$_.Path}

#$PasswordGenerator = "..\publish\PasswordGenerator.exe "
$PasswordGenerator = "..\..\bin\Release\net5.0\win10-x64\publish\PasswordGenerator.exe"
Stop-Transcript -ErrorAction SilentlyContinue | Out-Null 

$ReadOrCreateChoice = Read-Host -Prompt " Would you like to view an existing Password or create a new Password (v to View, c to Create)"

if ($ReadOrCreateChoice.Trim().ToLower() -eq "c")
{
    $transcriptOutputFileName = $env:TEMP + "\pgenoutput" + [System.DateTime]::Now.ToShortDateString().ToString().Replace("/","") + [System.DateTime]::Now.ToShortTimeString().ToString().Replace(" ","").Replace(":","") + ".txt"
    Start-Transcript -Path $transcriptOutputFileName -Append -Force
    & $PasswordGenerator 
    Stop-Transcript | Out-Null
    #>> $env:TEMP\output.txt
    $transcriptOutPut = Get-Content $transcriptOutputFileName 
    foreach ($line in $transcriptOutPut)
    { 
        if ($line.ToString().Contains("Output"))
        {
            $charArray = $line.Split("-")
            $outputPasswordFile = $charArray[1].Trim()
            #echo $outputPasswordFile
            $outputFile = $outputPasswordFile
        }
    
    }
    $EncryptPassword = Read-Host  -Prompt "Would you like to encrypt the password using Encryptor app after the password is created?(yes/no)"

    if ($EncryptPassword.Trim().ToLower() -eq "yes")
    {
        if (!(Get-Command $EncryptorCommand -ErrorAction SilentlyContinue))
        {
            echo "Encryptor is not installed"
            echo "Please install Encryptor to encrypt keys and add to Path on computer and try to encrypt"
            exit
        }
        else 
        {
            echo "Password will be encrypted"
            if (!((Test-Path -Path $sshPath$pGenPrivateKeyFile) -and (Test-Path -Path $sshPath$pGenPublicKeyFile)))
            {
                if (!(Get-Command ssh-keygen -ErrorAction SilentlyContinue))
                {
                    echo "ssh not installed on your system, we will now attempt to install SSH on your system"
                    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `".\InstallOpenSSH.ps1`"" -Verb RunAs; exit
                }
                $pkeypwd = ""
                $pvpwd =""
                while ($pkeypwd.Trim() -eq "")
                {
                    $pkeypwd = Read-Host -Prompt "Please enter a password for encryption key. Please ensure to remember this password as the key is required to decrypt the password file once encrypted" -AsSecureString
                    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pkeypwd)
                    $pvpwd = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                    if ($pvpwd.Trim() -eq "")
                    {
                        echo "Encryption of file cannot continue without valid password...provide input a valid password"
                    }
                }                
                & ssh-keygen.exe -f "$sshPath$pGenPrivateKeyFile" -P $pvpwd
                & ssh-keygen.exe -f "$sshPath$pGenPrivateKeyFile.pub" -e -m pem > $sshPath$pGenPublicKeyFile
                #Copy-Item -Path "$sshPath$pGenPrivateKeyFile.pub" -Destination "$sshPathtemp.pub"
                Remove-Item -Path "$sshPath$pGenPrivateKeyFile.pub" -ErrorAction SilentlyContinue

                $pubkeylines = Get-Content -Path "$sshPath$pGenPublicKeyFile"
                $builder = New-Object -TypeName System.Text.StringBuilder
                #$builder.AppendLine("-----BEGIN PUBLIC KEY-----")
                foreach ($publine in $pubkeylines)
                {
                    if ($publine.Contains("RSA"))
                    {
                        $publine = $publine.Replace("RSA ","")
                    }
                    $builder.AppendLine($publine)
                }
                #$builder.AppendLine("-----END PUBLIC KEY-----")
                Set-Content -Path "$sshPath$pGenPublicKeyFile" -Value $builder.ToString()
                #Remove-Item -Path "$sshPathtemp.pub" -ErrorAction SilentlyContinue#>
            }
            Start-Process $EncryptorCommand -ArgumentList "--e --k $sshPath$pGenPublicKeyFile --i $outputPasswordFile --o $outputPasswordFile.enc" -NoNewWindow
        }
    }
}

