#!/bin/bash -l

echo
echo "Swift/T with Python starts ..."
echo

if (( ${#ROOT} == 0  ))
then
	echo "Set ROOT as the parent installation directory!"
	exit 1
fi

if [ -d $ROOT ]
then
	echo "Removing installed swift-t ..."
	rm -rf $ROOT/swift-t-install
	mkdir -pv $ROOT/swift-t-install
else 
	echo "There does not exist $ROOT!"
	exit 1
fi

# echo "Loading Modules ..."
# module load intel/17.0.4-74uvhji
# module load jdk/8u141-b15-mopj6qr
# module load tcl/8.6.6-x4wnbsg
# echo "Modules are loaded!"

set -eu

# Download Java
# wget --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u192-b12/750e1c8617c5452694857ad95c3ee230/jdk-8u192-linux-x64.tar.gz
# if [ -d $ROOT/jdk1.8.0_192 ]
# then
#	rm -rv $ROOT/jdk1.8.0_192
# fi
# tar -zxvf jdk-8u192-linux-x64.tar.gz -C $ROOT
# export JAVA_HOME=$ROOT/jdk1.8.0_192
# export PATH=$JAVA_HOME/bin:$PATH
# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$JAVA_HOME/lib

# Download Ant
if [ -f apache-ant-1.10.7-bin.tar.gz ]
then
	rm -fv apache-ant-1.10.7-bin.tar.gz
fi
if wget -q http://ftp.wayne.edu/apache//ant/binaries/apache-ant-1.10.7-bin.tar.gz
then
	echo WARNING: wget exited with: $?
fi
if [ -d $ROOT/apache-ant-1.10.7 ]
then
        rm -rf $ROOT/apache-ant-1.10.7
fi
tar -zxvf apache-ant-1.10.7-bin.tar.gz -C $ROOT
source env-ant.sh

echo
echo "Download Swift/T source code ..."
if [ -d swift-t ]
then
	echo "Backing up the previous Swift/T source code"
	rm -rf swift-t-bak
	mv swift-t swift-t-bak
fi
git clone https://github.com/swift-lang/swift-t.git

# Setup Swift/T
cd swift-t
# git push origin --delete tong01
# git checkout -b tong01
# cp -f ../MPIX_Comm_launch.c turbine/code/src/tcl/launch/MPIX_Comm_launch.c
# cp -f ../launch.c turbine/code/src/tcl/launch/launch.c
# git add turbine/code/src/tcl/launch/MPIX_Comm_launch.c turbine/code/src/tcl/launch/launch.c
# git commit -m "launch"
# git push --set-upstream origin tong01
# git branch
# git status
git checkout remotes/origin/tong01
dev/build/init-settings.sh
sed -i 's/^export SWIFT_T_PREFIX=\/tmp\/swift-t-install$/export SWIFT_T_PREFIX='"${ROOT//\//\\/}"'\/swift-t-install/' dev/build/swift-t-settings.sh

PYTHON_EXE=$( which python )
sed -i 's/^ENABLE_PYTHON=0/ENABLE_PYTHON=1/' dev/build/swift-t-settings.sh
sed -i 's@^PYTHON_EXE=.*$@PYTHON_EXE='"$PYTHON_EXE"'@' dev/build/swift-t-settings.sh

echo
echo "Build Swift/T ..."
dev/build/build-swift-t.sh
cd ..

source env-swiftT.sh

echo
echo "Swift/T with Python is done!"
echo

