#!/bin/bash 
HOST_WRF_DIR="$HOME/WRF"		# Directory containing WRF code and volume
CONT_WRF_DIR="/root/WRF"		
HOST_VOL_DIR="$HOST_WRF_DIR/data"	# Volume to mount
CONT_VOL_DIR="$CONT_WRF_DIR/data"
HOST_SHARED_DIR="$HOST_VOL_DIR/shared"	# Directory with microservice output directories
HOST_NAMELIST_LOC="$HOST_WRF_DIR/WRF_NIST_Microservices_Public"	# Directory containing namelist to mount
CONT_WPS_LOC="$CONT_WRF_DIR/WPS"	# Directory with WPS executables
CONT_WRF_LOC="$CONT_WRF_DIR/WRFV3"	# Top directory of WRFV3

CONT_DATA_DIR="$CONT_VOL_DIR/FNL_JAN_MAR_2005"	# Location of dataset in volume
DATA_PREFIX="fnl_200501"			# Because ungrib processes all data linked in, a prefix greatly reduces
						# ungrib runtime. All files in the dataset with this prefix will be processed.
VTABLE="Vtable.GFS"				# Specific to external dataset used.

MICROSERVICES=("geogrid" "ungrib" "metgrid" "real" "wrf")

echo "Starting WPS and WRF Orchestrator..."

# Creates output folders if needed
echo "Checking for required output directories in $HOST_SHARED_DIR"
for executable in "${MICROSERVICES[@]}"
do
	if [ ! -d "$HOST_SHARED_DIR/${executable}_output" ]; then
		mkdir $HOST_SHARED_DIR/${executable}_output
		echo "Created ${executable}_output directory."
	fi
done

# Cleans microservice output for a fresh run
echo "Clearing microservice output directories..."
for executable in "${MICROSERVICES[@]}"
do
	rm -rf $HOST_SHARED_DIR/${executable}_output/*
done

echo "Clearing previous wsm6 containers"
sudo docker kill wsm6 &> /dev/null
sudo docker rm wsm6 >& /dev/null

echo "Clearing previous log files..."
for executable in "${MICROSERVICES[@]}"
do
	rm ${executable}.log &> /dev/null
done

echo "Running WPS and WRF. Output will be stored in *.log files."

echo "Running geogrid..."
sudo docker run --rm --name geogrid -v $HOST_VOL_DIR:$CONT_VOL_DIR -v $HOST_NAMELIST_LOC/namelist.wps:$CONT_WPS_LOC/namelist.wps wrf:geogrid &> geogrid.log
if ! grep -q "Successful completion of geogrid" geogrid.log ; then
	echo "Problem running geogrid. Check geogrid.log for more details."
	exit 1
fi

echo "Geogrid finished successfully. Running ungrib..."
sudo docker run --rm --name ungrib -v $HOST_VOL_DIR:$CONT_VOL_DIR -v $HOST_NAMELIST_LOC/namelist.wps:$CONT_WPS_LOC/namelist.wps wrf:ungrib $VTABLE $CONT_DATA_DIR/${DATA_PREFIX}\* &> ungrib.log
if ! grep -q "Successful completion of ungrib" ungrib.log ; then
	echo "Problem running ungrib. Check ungrib.log for more details."
	exit 1
fi

echo "Ungrib finished successfully. Running metgrid..."
sudo docker run --rm --name metgrid -v $HOST_VOL_DIR:$CONT_VOL_DIR -v $HOST_NAMELIST_LOC/namelist.wps:$CONT_WPS_LOC/namelist.wps wrf:metgrid &> metgrid.log
if ! grep -q "Successful completion of metgrid" metgrid.log ; then
	echo "Problem running metgrid. Check metgrid.log for more details."
	exit 1
fi

echo "Metgrid finished successfully. Running real..."
sudo docker run --rm --name real -v $HOST_VOL_DIR:$CONT_VOL_DIR -v $HOST_NAMELIST_LOC/namelist.input:$CONT_WRF_LOC/test/em_real/namelist.input wrf:real >& real.log
if ! grep -q "SUCCESS COMPLETE REAL_EM INIT" real.log ; then
	echo "Problem running real. Check real.log for more details."
	exit 1
fi

echo "Real finished successfully. Running wrf..."
sudo docker run --rm --name wrf -v $HOST_VOL_DIR:$CONT_VOL_DIR -v $HOST_NAMELIST_LOC/namelist.input:$CONT_WRF_LOC/test/em_real/namelist.input -v /var/run/docker.sock:/var/run/docker.sock -e "WRF_HST_DATA_DIR=$HOST_VOL_DIR" wrf:wrf &> wrf.log
if ! grep -q "Successful completion of wrf" wrf.log ; then
	echo "Problem running wrf. Check wrf.log for more details."
	exit 1
fi

echo "WRF model exited successfully. Model output is stored in netCDF format in $HOST_SHARED_DIR/wrf_output"
