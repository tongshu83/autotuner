#!/bin/bash
set -eu

# WORKFLOW SH
# Main user entry point

if [[ ${#} != 2 ]]
then
	echo "Usage: ./workflow.sh workflow_name experiment_id"
	exit 1
fi

WORKFLOW_SWIFT=$1.swift
WORKFLOW_TIC=${WORKFLOW_SWIFT%.swift}.tic

export EXPID=$2

# Turn off Swift/T debugging
export TURBINE_LOG=0 TURBINE_DEBUG=0 ADLB_DEBUG=0

# Find the directory of ./workflow.sh
export WORKFLOW_ROOT=$( cd $( dirname $0 ) ; /bin/pwd )
cd $WORKFLOW_ROOT

if [[ $1 = "gs" ]]
then
	export TURBINE_OUTPUT=$WORKFLOW_ROOT/bp4/$EXPID
	mkdir -pv $TURBINE_OUTPUT
	cd $TURBINE_OUTPUT
	cp -f ../smpl_gs.csv smpl_gs.csv
	cp -f ../settings-files.json settings-files.json
	cp -f ../adios2.xml adios2.xml
	cd -
fi

if [[ $1 = "pdf" ]]
then
	export TURBINE_OUTPUT=$WORKFLOW_ROOT/bp4/$EXPID
	mkdir -pv $TURBINE_OUTPUT
	cd $TURBINE_OUTPUT
	cp -f ../smpl_pdf.csv smpl_pdf.csv
	cp -f ../adios2.xml adios2.xml
	cd -
fi

if [[ $1 = "gp" ]]
then
	# Set the output directory
	export TURBINE_OUTPUT=$WORKFLOW_ROOT/sst/$EXPID
	mkdir -pv $TURBINE_OUTPUT
	cd $TURBINE_OUTPUT
	cp -f ../smpl_gp.csv smpl_gp.csv
	cp -f ../settings-staging.json settings-staging.json
	cp -f ../adios2.xml adios2.xml
	cd -
fi

if (( ${#TURBINE_OUTPUT} == 0  ))
then
	echo "Set TURBINE_OUTPUT as the output directory!"
	exit 1
fi

cp -f $WORKFLOW_ROOT/get_maxtime.sh $TURBINE_OUTPUT/get_maxtime.sh

# Total number of processes available to Swift/T
# Of these, 2 are reserved for the system
export PROCS=6
export PPN=1
export WALLTIME=00:10:00
export PROJECT=WORKFLOW
export QUEUE=bdw

MACHINE="-m slurm" # -m (machine) option that accepts pbs, cobalt, cray, lsf, theta, or slurm. The empty string means the local machine.

ENVS="" # "-e <key>=<value>" Set an environment variable in the job environment.

set -x
stc -p -O0 $WORKFLOW_ROOT/$WORKFLOW_SWIFT
# -p: Disable the C preprocessor
# -u: Only compile if target is not up-to-date

turbine -l $MACHINE -n $PROCS $ENVS $WORKFLOW_ROOT/$WORKFLOW_TIC
# -l: Enable mpiexec -l ranked output formatting
# -n <procs>: The total number of Turbine MPI processes

#swift-t -l $MACHINE -p -n $PROCS $ENVS $WORKFLOW_ROOT/workflow.swift

echo WORKFLOW COMPLETE.

