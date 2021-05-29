#!/bin/bash
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
defaultsshPath="$HOME/.ssh"
pGenPrivateKeyFile='pGenKeyFile.pem'
pGenPublicKeyFile='pGenKeyFile.pub'
defaultpGenPath="$HOME/PGenData"
scriptName=$(basename "$0")
echo "Running $scriptName"
defaultpGenScriptPath=$(command -v "$scriptName")
defaultpGenScriptPath=$(echo $defaultpGenScriptPath | sed -e "s/\/$scriptName//")
cd $defaultpGenScriptPath
defaultPasswordGeneratorPath=$(cd "../publish";pwd)
echo "PasswordGenerator installed at $defaultPasswordGeneratorPath"
passwordGenerator="PasswordGenerator"
encryptor="Encryptor"

if [ ! -d $defaultpGenPath ]; then
    echo "Creating Default Application path $defaultpGenPath for storing passwords"
    mkdir $defaultpGenPath
    echo "Created $defaultpGenPath....The folder should not be deleted to avoid data loss"
fi
echo "Press [ENTER] to continue....."
read s

if [ ! -f $defaultsshPath/$pGenPrivateKeyFile ]; then
    if ! command -v openssl ; then
        echo "OpenSSL is not installed, required for generating keys...exiting"
        exit
    fi
    echo "There are no keys available on your systems. Keys are required to encrypt and decrypt password data. You will now be asked for a password to use with the key on your machine"
    echo "It is critical that you use a password that you can remember as it will be required when new passwords are to be generated/encrypted/decrypted"
    echo "Please enter your password"
    stty -echo
    read s
    stty echo
    pvpwd=$s
    if [ -z $pvpwd ]; then
        echo "Valid Password is required, Cannot continue, exiting..."
        exit
    fi
    openssl genrsa -out $defaultsshPath/$pGenPrivateKeyFile -passout pass:$pvpwd -aes256 2048
    openssl rsa -in $defaultsshPath/$pGenPrivateKeyFile -passin pass:$pvpwd -pubout -out $defaultsshPath/$pGenPublicKeyFile

    if [ ! -f $defaultsshPath/$pGenPrivateKeyFile ] || [ ! -f $defaultsshPath/$pGenPublicKeyFile ]; then
        echo " Could not generate keys...exiting"
        exit
    fi
fi

echo "Would you like to view an existing Password or create a new Password (v to View, c to Create)"
read ans

if [ \( "$ans" = 'c' \) ]; then
    dd=$(date +%m%d%y%H%M%S)
    #echo $dd
    $defaultPasswordGeneratorPath/$passwordGenerator 2>&1 | tee /tmp/$dd
    outfile=$(cat /tmp/$dd | grep 'Output' | awk -F '-' '{print $NF}')
    echo $outfile
    if ! command -v $encryptor ; then
        echo "Please install Encryptor to ensure passwords are encrypted after they are created..."
        echo "Exiting app without Encrypting password file...."
        exit
    fi
    echo "Would you like to view new password generated before file is encrypted (yes/no):"
    read choice
    if [ \( "$choice" = 'yes' \) -o \( "$choice" = 'YES' \) ]; then
        outfile=$(echo $outfile | sed -e 's/^[[:space:]]*//')
        cat $outfile
    fi
    ext=$(echo $outfile | awk -F '.' '{print "."$NF}')
    #echo $ext
    replaceext="$ext.enc"
    #echo $replaceext
    outfilename=$(echo $outfile | sed -e "s|$ext|$replaceext|g")
    #echo $outfilename
    $encryptor --e --k $defaultsshPath/$pGenPublicKeyFile --i $outfile --o $outfilename
fi

#for fl in `ls -p $defaultsshPath | grep -v '/$'`; do
#    echo $fl
#done
IFS=$SAVEIFS
