#!/bin/bash
THIS_DIR=$(pwd)
cd ~/WRF/data/shared
./clean.sh
sudo docker kill wsm6
sudo docker rm wsm6
cd $THIS_DIR
sudo docker run --rm --name geogrid -v ~/WRF/data/:/root/WRF/data -v ~/WRF/WRF_NIST_Microservices_Public/namelist.wps:/root/WRF/WPS/namelist.wps wrf2:geogrid
sudo docker run --rm --name ungrib -v ~/WRF/data/:/root/WRF/data -v ~/WRF/WRF_NIST_Microservices_Public/namelist.wps:/root/WRF/WPS/namelist.wps wrf2:ungrib Vtable.GFS /root/WRF/data/FNL_2005_2007/fnl_200501\*
sudo docker run --rm --name metgrid -v ~/WRF/data/:/root/WRF/data -v ~/WRF/WRF_NIST_Microservices_Public/namelist.wps:/root/WRF/WPS/namelist.wps wrf2:metgrid
sudo docker run --rm --name real -v ~/WRF/data/:/root/WRF/data -v ~/WRF/WRF_NIST_Microservices_Public/namelist.input:/root/WRF/WRFV3/test/em_real/namelist.input wrf2:real
sudo docker run --rm --name wrf -v ~/WRF/data/:/root/WRF/data -v ~/WRF/WRF_NIST_Microservices_Public/namelist.input:/root/WRF/WRFV3/test/em_real/namelist.input -v /var/run/docker.sock:/var/run/docker.sock -e "WRF_HST_DATA_DIR=/home/keirouz/WRF/data" wrf2:wrf
