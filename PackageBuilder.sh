#!/bin/sh

RootDir=$PWD
#echo $RootDir
packagename='cRelayMqttWrapperService'
version=0.8
basedir="${RootDir}/${packagename}.ipk/"
#echo $basedir

cd $basedir/
TmpDir="${basedir}TmpDir"
mkdir $TmpDir


cd $basedir/CONTROL
#echo tar -vczf $TmpDir/control.tar.gz ./*
tar -czf $TmpDir/control.tar.gz ./*

cd $basedir/data
#echo tar -vczf $TmpDir/data.tar.gz ./*
tar -czf $TmpDir/data.tar.gz ./*

packagenameComp="${packagename}.${version}.all.ipk"
#echo $packagenameComp
echo "2.0" > $TmpDir/debian-binary
cd $TmpDir
tar -czf $RootDir/$packagenameComp ./*

rm -rf $TmpDir
exit 1



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

echo "finished building ipk"