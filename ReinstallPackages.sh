#!/bin/sh

Testing=0
#define some internal global variables
INSTALL=1
PKGS=""
FileName=""
PkgName=""

#The actual work is done here
handlePackage()
{
#clear strings
PkgName=""
FileName=""
echo

if [ -f "$1" ]; then
	#get Package Name From File	
	echo ➜ getting package name from file
	PkgName=$(tar -Oxzf $1 ./control.tar.gz | tar -xzO | grep '^Package:' | cut -d' ' -f2)
	if [ -z "$PkgName" ]; then
		echo "❌ Could not extract package name from $ipk"
		exit
	fi	
	FileName=$1
else
	#get the filname from the package
	echo ➜ getting file name from package
	PkgName=$1
	FileName=$(find . -maxdepth 1 -type f -name "${PkgName}*.all.ipk" | head -n 1)	
fi

# now to remove the package
if [ "$PkgName" != "" ] ; then
	echo "📦 Package name: $PkgName"
	# Uninstall the package if it's already installed
	if opkg list-installed | grep -q "^$PkgName "; then
    echo "🔄 Uninstalling $PkgName..."
	if [ "$Testing" -ne 1 ]; then
		opkg remove "$PkgName"
	else
		echo testing cmd: opkg remove "$PkgName"
	fi
  else
    echo "ℹ️ $PkgName not currently installed"
  fi
fi

#install if thats needed
if [ $INSTALL -eq 1 ]; then
	if [ "$FileName" != "" ] ; then
		# Install the package from the .ipk file
		echo "📥 Installing $PkgName from $FileName..."
		if [ "$Testing" -ne 1 ]; then
			opkg install "$FileName"
		else
			echo testing cmd: opkg install "$FileName"
		fi
		echo "✅ Done with $PkgName"
		echo "-----------------------------"
	fi
fi
echo
}

# see if we have parameters
if [ "$#" -ne 0 ]; then
	if [ "$1" = "remove" ]; then 
		#only remove
		echo remove packages
		INSTALL=0
		shift #shifts to the next parameter
	fi
fi

if [ "$#" -ne 0 ]; then	
	# Parse the rest of the arguments
	while [ "$#" -gt 0 ]; do
	   handlePackage $1
	  shift
	done
  exit 1 # were done here
fi

echo Search all files
for ipk in *.all.ipk; do
  echo "Processing: $ipk"
  handlePackage $ipk
done
