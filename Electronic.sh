#!/bin/bash

BASE_DIR=$PWD
cd electronic 2>/dev/null
if [ $1 == scrun ]; then
    cd $BASE_DIR
    mkdir electronic
    cd electronic
    cp -r ../INPUT .
#    sed -i "/PREC/c PREC = Accurate" INPUT/INCAR
#    sed -i "/NSW/c NSW = 0" INPUT/INCAR
    sed -i "/LCHARG/c LCHARG = .TRUE." INPUT/INCAR
    sed -i "/LMAXMIX/c LMAXMIX = 4" INPUT/INCAR

    sed -i "/NPAR/c NPAR = 8"  INPUT/INCAR
    sed -i "/#PBS -l walltime/c #PBS -l walltime=03:00:00" INPUT/qsub.parallel
    sed -i "/#PBS -l nodes/c #PBS -l nodes=1:ppn=8" INPUT/qsub.parallel
    Fast-prep.sh scrun
    cd scrun
    qsub qsub.parallel

elif [ $1 == dosrun ]; then
    Fast-prep.sh dosrun
    cd dosrun
    cp ../scrun/CONTCAR POSCAR
    cp -l ../scrun/CHGCAR .
    sed -i '4c 21 21 21' KPOINTS

    sed -i "/NSW/c NSW = 0" INCAR
    sed -i "/ISMEAR/c ISMEAR = -5" INCAR
    sed -i "/NEDOS/c NEDOS = 1501" INCAR
    sed -i "/ICHARG/c ICHARG = 11" INCAR
    if [[ $2 == rwigs ]]; then
        rwigs=$(cd ../scrun; Cellinfo.sh rwigs |awk '{print $4}')
        sed -i "/RWIGS/c RWIGS = ${rwigs//,/ }" INCAR
        sed -i "/NPAR/c NPAR = 1" INCAR
        sed -i "/LORBIT/c LORBIT = 1"  INCAR
    else
        sed -i "/NPAR/c NPAR = 8"  INCAR
        sed -i "/LORBIT/c LORBIT = 11"  INCAR
    fi

    sed -i "/#PBS -l walltime/c #PBS -l walltime=04:00:00" qsub.parallel
    sed -i "/#PBS -l nodes/c #PBS -l nodes=2:ppn=8" qsub.parallel
    qsub qsub.parallel

elif [ $1 == bsrun ]; then
    Fast-prep.sh bsrun
    cd bsrun
    cp ../scrun/CONTCAR POSCAR
    cp -l ../scrun/CHGCAR .

    if [ -f KPOINTS-bs ]; then
        mv KPOINTS-bs KPOINTS
    else
        echo "You must manually change the KPOINTS file before submitting job!"
        exit 1
    fi

    sed -i "/NSW/c NSW = 0" INCAR
    sed -i "/NEDOS/c NEDOS = 1501" INCAR
    sed -i "/ICHARG/c ICHARG = 11" INCAR
    sed -i "/LORBIT/c LORBIT = 11" INCAR

    sed -i "/NPAR/c NPAR = 8"  INCAR
    sed -i "/#PBS -l walltime/c #PBS -l walltime=04:00:00" qsub.parallel
    sed -i "/#PBS -l nodes/c #PBS -l nodes=2:ppn=8" qsub.parallel
    qsub qsub.parallel

elif [ $1 == lobster-kp ]; then
    Fast-prep.sh lobster-kp qlobster.kp.serial
    cd lobster-kp
    cp ../scrun/CONTCAR POSCAR
    sed -i '4c 17 17 17' KPOINTS

    sed -i "/NSW/c NSW = 0" INCAR
    sed -i "/ISYM/c ISYM = 0" INCAR
    sed -i "/LSORBIT/c LSORBIT = .TRUE." INCAR
    sed -i "/ISMEAR/c ISMEAR = -5" INCAR
    qsub qlobster.kp.serial

elif [ $1 == lobster-prerun ]; then
    Fast-prep.sh lobster qlobster.parallel
    cd lobster
    if [[ -d ../lobster-kp ]]; then
        mv ../lobster-kp .
    fi
    cp lobster-kp/IBZKPT KPOINTS

    if [[ -f ../scrun/CHGCAR ]]; then
        cp ../scrun/CONTCAR POSCAR
        cp -l ../scrun/CHGCAR .
        sed -i "/ICHARG/c ICHARG = 11" INCAR
    fi

    if [[ -n $2 ]]; then
        sed -i "/NBANDS/c NBANDS = $2" INCAR
    fi

    sed -i "/NSW/c NSW = 0" INCAR
    sed -i "/ISMEAR/c ISMEAR = -5" INCAR
    sed -i "/NEDOS/c NEDOS = 1501" INCAR
    sed -i "/LORBIT/c LORBIT = 10"  INCAR
    sed -i "/LWAVE/c LWAVE = .TRUE." INCAR

    sed -i "/NPAR/c NPAR = 8"  INCAR
    sed -i "/#PBS -l walltime/c #PBS -l walltime=05:00:00" qsub.parallel
    sed -i "/#PBS -l nodes/c #PBS -l nodes=2:ppn=8" qsub.parallel
    qsub qsub.parallel

elif [ $1 == lobster ]; then
    cd lobster
    qsub qlobster.parallel

elif [ $1 == plot-ldos ]; then
    cd dosrun
    _Plot-ldos.py $2 $3

elif [ $1 == plot-tdos ]; then
    cd dosrun
    _Plot-tdos.py $2

elif [ $1 == plot-bs ]; then
    cd bsrun
    _Plot-bs.py $2
fi
