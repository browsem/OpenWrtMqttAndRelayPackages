#!/bin/sh

BuildPack(){

cd $basedir/
TmpDir="${basedir}TmpDir"
mkdir $TmpDir


cd $basedir/CONTROL
#echo tar -vczf $TmpDir/control.tar.gz ./*
tar -czf $TmpDir/control.tar.gz ./*

cd $basedir/data
#echo tar -vczf $TmpDir/data.tar.gz ./*
tar -czf $TmpDir/data.tar.gz ./*


#echo $packagenameComp
echo "2.0" > $TmpDir/debian-binary
cd $TmpDir
tar -czf $RootDir/$packagenameComp ./*

rm -rf $TmpDir
echo "finished building ${packagename} ipk"
}

notToBeUsed(){
#!/bin/sh

basedir='/opt/root/helloworld-package'
#/home/user/Desktop/examples/helloworld-package'

cd $basedir/
mkdir tmp
cd $basedir/control
tar -czf ../tmp/control.tar.gz ./*

cd $basedir/data
tar -czf ../tmp/data.tar.gz ./*

packagename="helloworld-package_3.0.arm_cortex-a9.ipk"

cd $basedir

cp debian-binary tmp
cd tmp
tar -czf ../../$packagename ./*

# clean up
cd ..
rm -rf tmp

echo "finished building ${packagename} ipk"

}



RootDir=$PWD
packagename='cRelayMqttWrapperService'
version=0.8
packagenameComp="${packagename}.${version}.all.ipk"

basedir="${RootDir}/${packagename}.ipk/"
echo "building ${packagenameComp}" 
echo "in folder"
echo "${basedir}"
BuildPack


