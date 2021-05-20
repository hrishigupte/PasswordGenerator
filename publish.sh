#!/bin/bash
rm -rf obj/*
rm -rf ~/.local/share/Trash/files/*
rm -rf bin/Release/net5.0/*
dotnet publish -c Release --self-contained -r ubuntu.16.04-x64
dotnet publish -c Release --self-contained -r win10-x64
dotnet publish -c Release --self-contained -r opensuse-x64
dotnet publish -c Release --self-contained -r osx-x64

cd bin/Release/net5.0
cp -r ../../../Scripts/linux ubuntu.16.04-x64/.
cp -r ../../../Scripts/win10 win10-x64/.
cp -r ../../../Scripts/linux opensuse-x64/.
cp -r ../../../Scripts/linux osx-x64/.
if ! command -v tar
then
	echo "tar not found"
else
	tar -cvf PasswordGenerator-ubuntu.16.04-x64.tar ubuntu.16.04-x64/*
	tar -cvf PasswordGenerator-opensuse-x64.tar opensuse-x64/*
	tar -cvf PasswordGenerator-osx-x64.tar osx-x64/*
fi
if ! command -v zip
then
	echo "zip not found"
else
	zip -r PasswordGenerator-win10-x64.zip win10-x64/*
fi
