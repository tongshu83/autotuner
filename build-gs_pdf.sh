#!/bin/bash -l

echo
echo "Gray-scott and PDF calculation start ..."
echo

if (( ${#ROOT} == 0 ))
then
	echo "Set ROOT as the parent installation directory!"
	exit 1
fi

set -eu

echo "Download applications ..."
rm -rf adiosvm
if [ -d gray-scott ]
then
	echo "Backing up the previous gray-scott ..."
	rm -rf gray-scott-bak
	mv gray-scott gray-scott-bak
fi
git clone https://github.com/pnorbert/adiosvm.git

echo
echo "Build Gray-scott and PDF calculation ..."
echo 'mv adiosvm/Tutorial/gray-scott gray-scott'
mv adiosvm/Tutorial/gray-scott gray-scott
echo 'rm -rf adiosvm'
rm -rf adiosvm
echo 'gray-scott'
cd gray-scott
echo 'mkdir build'
mkdir build
echo 'cd build'
cd build
echo 'export ADIOS2_DIR=$ROOT/adios2'
export ADIOS2_DIR=$ROOT/adios2
echo 'cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo ..'
cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo ..
echo 'make -j 8'
make -j 8
echo 'cd ..'
cd ..

echo
echo "Testing Gray-scott and PDF calculation ..."
sed -i 's/^    "steps": .*,$/    "steps": 100,/' simulation/settings-files.json
sed -i 's/^    "adios_span" : .*,$/    "adios_span" : false,/' simulation/settings-files.json
sed -i 's/^    "steps": .*,$/    "steps": 100,/' simulation/settings-staging.json
sed -i 's/^    "adios_span" : .*,$/    "adios_span" : false,/' simulation/settings-staging.json

echo
echo "Testing BPFile engine ..."
rm -rf BPgsplot
mkdir -pv BPgsplot
rm -rf BPpdfplot
mkdir -pv BPpdfplot
sed -i 's@^            <operation type="sz">$@            <!--operation type="sz"-->@' adios2.xml
sed -i 's@^                <parameter key="accuracy" value="0.001"/>$@                <!--parameter key="accuracy" value="0.001"/-->@' adios2.xml
sed -i 's@^            </operation>$@            <!--/operation-->@' adios2.xml
sed -i 's/^import matplotlib.pyplot as plt$/import matplotlib\nmatplotlib.use("Agg")\nimport matplotlib.pyplot as plt/' plot/gsplot.py
sed -i 's/^import matplotlib.pyplot as plt$/import matplotlib\nmatplotlib.use("Agg")\nimport matplotlib.pyplot as plt/' plot/pdfplot.py
echo 'mpiexec -n 2 build/gray-scott simulation/settings-files.json'
mpiexec -n 2 build/gray-scott simulation/settings-files.json
echo 'bpls -l gs.bp'
bpls -l gs.bp
echo 'mpiexec -n 1 python3 plot/gsplot.py -i gs.bp -o BPgsplot/img'
mpiexec -n 1 python3 plot/gsplot.py -i gs.bp -o BPgsplot/img
echo 'mpiexec -n 2 build/pdf_calc gs.bp pdf.bp 100'
mpiexec -n 2 build/pdf_calc gs.bp pdf.bp 100
echo 'bpls -l pdf.bp'
bpls -l pdf.bp
echo 'mpiexec -n 2 python3 plot/pdfplot.py -i pdf.bp -o BPpdfplot/fig'
mpiexec -n 2 python3 plot/pdfplot.py -i pdf.bp -o BPpdfplot/fig
ls -l BPgsplot
ls -l BPpdfplot

sed -i ':a;N;$!ba;s/        <engine type="BP4">/        <engine type="SST">/1' adios2.xml
sed -i ':a;N;$!ba;s/        <engine type="BP4">/        <engine type="SST">/1' adios2.xml
sed -i ':a;N;$!ba;s@            <parameter key="RendezvousReaderCount" value="0"/>@            <parameter key="RendezvousReaderCount" value="2"/>@1' adios2.xml
sed -i ':a;N;$!ba;s@            <parameter key="QueueFullPolicy" value="Discard"/>@            <parameter key="QueueFullPolicy" value="Block"/>@1' adios2.xml

echo
echo "Testing SST engine ..."
rm -rf SSTgsplot
mkdir -pv SSTgsplot
rm -rf SSTpdfplot
mkdir -pv SSTpdfplot
echo 'mpiexec -n 2 build/gray-scott simulation/settings-staging.json &'
mpiexec -n 2 build/gray-scott simulation/settings-staging.json &
echo 'mpiexec -n 1 build/pdf_calc gs.bp pdf.bp 100 &'
mpiexec -n 1 build/pdf_calc gs.bp pdf.bp 100 &
echo 'mpiexec -n 1 python3 plot/pdfplot.py -i pdf.bp -o SSTpdfplot/fig &'
mpiexec -n 1 python3 plot/pdfplot.py -i pdf.bp -o SSTpdfplot/fig &
echo 'mpiexec -n 1 python3 plot/gsplot.py -i gs.bp -o SSTgsplot/img'
mpiexec -n 1 python3 plot/gsplot.py -i gs.bp -o SSTgsplot/img
ls -l SSTgsplot
ls -l SSTpdfplot

echo
echo "Testing SST engine with MPMD ..."
rm -rf SSTgsplotMPMD
mkdir -pv SSTgsplotMPMD
rm -rf SSTpdfplotMPMD
mkdir -pv SSTpdfplotMPMD
echo 'mpiexec -n 2 build/gray-scott simulation/settings-staging.json : -n 1 build/pdf_calc gs.bp pdf.bp 100 : -n 1 python3 plot/pdfplot.py -i pdf.bp -o SSTpdfplotMPMD/fig : -n 1 python3 plot/gsplot.py -i gs.bp -o SSTgsplotMPMD/img'
mpiexec -n 2 build/gray-scott simulation/settings-staging.json :        \
        -n 1 build/pdf_calc gs.bp pdf.bp 100 :                  \
        -n 1 python3 plot/pdfplot.py -i pdf.bp -o SSTpdfplotMPMD/fig : \
        -n 1 python3 plot/gsplot.py -i gs.bp -o SSTgsplotMPMD/img
ls -l SSTgsplotMPMD
ls -l SSTpdfplotMPMD

cd ../../..

echo
echo "Gray-scott and PDF calculation are done!"
echo

