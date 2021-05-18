#!/bin/tcsh

#############################################################
# script to run mc-single-arm in batch farm
# By Jixie Zhang, March 8, 2021
# 1) How to allow multiple jobs are running at the same time?
#    mc-single-arm need to read input file from ../infiles/, and place
#    output files #into ../outfiles/ and ../worksim/.
#    It allows to run only one single job with the same input file at a time
#    My solution is to rename the input file ....
# 2) How to make the job last for longer to take advantage of the batch farm?
#    Due to rzdat file is limited to 2G, only run ~20M events can be simulated
#    in each job. Simulating 20M events takes about 30 minutes. My sulution
#    is to run 100 subruns in each run, one run per job. The output will be
#    identified as ****$run_$rubrun*****
#############################################################

#load your cern and root installation here
source /apps/root/5.34.36/setroot_CUE.csh

#the job will be executed at this location,
#you need to change it to your version since you could not write my dir
set WORKSPACE = /volatile/hallc/c-polhe3/jixie/mc-single-arm

if($#argv < 1) then
  echo "Error, you need to provide at lease one argument"
  echo "Usage: $0:t <path_to_inputfile> [run_min=1] [run_max=1] [WORKSPACE=$WORKSPACE] [number_of_subruns=10]"
  echo "       make sure that the input file is in lower case, otherwise there will not be root output"
  echo "       the output root files will be copied to $WORKSPACE/worksim, which could be a soft link of a dir in /cache or /volatile"
  exit
endif

set inp0 = ($1:t:r)
set runmin = 1
if($#argv >= 2) set runmin = ($2)
set runmax = 1
if($#argv >= 3) set runmax = ($3)
if($runmax < $runmin) set runmax = ($runmin)

if ( $# >= 4 ) set WORKSPACE = ($4)
if !(-d $WORKSPACE) then
  echo "mc-single-arm dir '$WORKSPACE' not exist, I quit ..."
  exit -1
endif

set number_of_subruns = 10
if ( $# >= 5 ) set number_of_subruns = ($5)
if ( $number_of_subruns < 1 ) set number_of_subruns = 1

#########################################
#check if the input file exist or not

if !(-f $1 ) then
    echo "input file $1 does not exist, I quit..."
    exit -1
endif

set start00 = `date +%s`
#########################################
#create WORKDIR, only jlab batch farm has this variable
set curdir = `pwd`

set JobName = mc_a1n_${runmin}to${runmax}
if ( !($?WORKDIR) )  set WORKDIR = ($curdir/${JobName}_${number_of_subruns})
if ( ! (-d $WORKDIR) ) mkdir -p $WORKDIR

#########################################
#copy files
cp -fr $WORKSPACE/src $WORKDIR/.
mkdir -p $WORKDIR/infiles $WORKDIR/outfiles $WORKDIR/worksim
cp -f $1 $WORKDIR/infiles/.

#this is the output dir
mkdir -p $WORKSPACE/worksim

#########################################
cd $WORKDIR/src
if !(-e mc_single_arm) make
if !(-e mc_single_arm) then
  echo "can not create executable mc_single_arm, I quit ..."
  exit -2
endif

set run = ($runmin)
while ($run <= $runmax)
  set start0 = `date +%s`
  set key0 = `printf "%03d" ${run}`

  set subrun = 0
  while ($subrun < $number_of_subruns)
    set start = `date +%s`
    set key = `printf "%03d_%02d" ${run} ${subrun}`

    #to allow multiple jobs at the same time, rename the inputfile
    set inp = ${inp0}_${key}
    set inp_lowercase = `echo $inp | tr '[A-Z]' '[a-z]'`
    cp -f ../infiles/${inp0}.inp ../infiles/${inp}.inp

    echo "Start mc-single-arm for run# ${run}_${subrun}, please wait with patient ... expected time is 16s per Million events."
    rm -f ../worksim/${inp}.rzdat ../outfiles/${inp}.out
./mc_single_arm << endofinput >! ../outfiles/${inp}_${run}.log
${inp}
endofinput

    echo "convert paw ntuple to root tree ... "
    h2root ../worksim/${inp_lowercase}.rzdat ../worksim/${inp}.root
    ls -lh ../worksim/${inp}.root  #to show the file size

    #remove the temp inp file and rzdat file
    if (-f ../worksim/${inp}.root) then
      rm -f ../infiles/${inp}.inp
      rm -f ../worksim/${inp_lowercase}.rzdat
    endif

  set end = `date +%s`
  @ runtime = $end - $start
  echo "done! wall-time for this subrun (${run}_${subrun}) = $runtime (s)"

    @ subrun = $subrun + 1
  end #while subrun
  #merge all subruns into one big run
  if ( $number_of_subruns > 1 ) then
    hadd -f -k ../worksim/${inp0}_${key0}.root ../worksim/${inp0}_${key0}_??.root
    set filename_to_check = ../worksim/${inp0}_${key0}.root
    #this line does not work
    set FileIsBad = `root.exe -b -l -q -e "TFile *f = TFile::Open(\"$filename_to_check\"); if ((!f) || f->IsZombie() || f->TestBit(TFile::kRecovered)) { cout << \"There is a problem with the file: $filename_to_check\n\"; exit(1); }"`

    if (-f ../worksim/${inp0}_${key0}.root && 0$FileIsBad == 0) then
      cp -fv ../worksim/${inp0}_${key0}.root $WORKSPACE/worksim/.
      rm -f ../worksim/${inp0}_${key0}_??.root
    else
      cp -fv ../worksim/${inp0}_${key0}_??.root $WORKSPACE/worksim/.
    endif
  endif

  set end = `date +%s`
  @ runtime = $end - $start0
  echo "done! wall-time for this run ($run) = $runtime (s)"

  @ run = $run + 1
end

#########################################
cd $curdir

set end = `date +%s`
@ runtime = $end - $start00
echo "done! Total wall-time = $runtime (s)"
