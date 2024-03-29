#!/bin/bash -l

echo
echo "ADIOS2 starts ..."
echo

if (( ${#ROOT} == 0  ))
then
	echo "Set ROOT as the parent installation directory!"
	exit 1
fi

if [ -d $ROOT ]
then
	echo "Removing installed adios2 ..."
	rm -rf $ROOT/adios2
	mkdir -pv $ROOT/adios2
else
	echo "There does not exist $ROOT!"
	exit 1
fi

set -eu

echo
echo "Download ADIOS2 source code ..."
if [ -d ADIOS2 ]
then
	echo "Removing the previous ADIOS2 source code ..."
	rm -rf ADIOS2
fi
if [ -d adios2-build ]
then
	echo "Backing up the previous adios2-build"
	rm -rf adios2-build-bak
	mv adios2-build adios2-build-bak
fi
git clone https://github.com/ornladios/ADIOS2.git
#cp -r ~/project/ADIOS2-060519 ./ADIOS2

echo
echo "Build ADIOS2 ..."
echo 'mkdir adios2-build'
mkdir adios2-build
echo 'cd adios2-build'
cd adios2-build
echo 'cmake -DCMAKE_INSTALL_PREFIX=$ROOT/adios2 -DADIOS2_USE_Fortran=OFF ../ADIOS2'
cmake -DCMAKE_INSTALL_PREFIX=$ROOT/adios2 -DADIOS2_USE_Fortran=OFF ../ADIOS2
echo 'make -j 8'
make -j 8
echo 'make install'
make install
echo '..'
cd ..

echo 'source env-adios2.sh'
source env-adios2.sh

echo
echo "ADIOS2 is done!"
echo
