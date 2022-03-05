set -e

CWD=`pwd`
#find . -name "*.sh" | xargs chmod +x
# environment variables for NVBit
export NOBANNER=1
# set TOOL_VERBOSE=1 to print debugging information during profling and injection runs 
export TOOL_VERBOSE=0
export VERBOSE=0

export NVBITFI_HOME=$CWD
export CUDA_BASE_DIR=/usr/local/cuda
export PATH=$PATH:$CUDA_BASE_DIR/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CUDA_BASE_DIR/lib64/:$CUDA_BASE_DIR/extras/CUPTI/lib64/
export DIRECTORY=$1
export NUM_JOBS=$3
printf "\nStep 0 (3): Build the nvbitfi injector and profiler tools\n"
cd injector 
#make clean
make
cd ../profiler/
#make clean
make
cd $CWD
printf "\nStep 0 (4): Run and collect output without instrumentation\n"

printf "COPIO IL FILE RUN\n"
cp "/$PWD/pattern/run.sh" "$1"

printf "sostituisco in run.sh app_name --> $2\n"
sed -i "s/app_name/$2/g" "$1/run.sh"

printf "COPIO IL FILE sdc_check\n"
cp "/$PWD/pattern/sdc_check.sh" "$1"

printf "COPIO IL FILE params.py\n"
cp "$PWD/pattern/params.py" "$PWD/scripts"

printf "sostituisco in params.py vectorAdd --> $2\n"
sed -i "s/app_name/$2/g" "$PWD/scripts/params.py"

#printf "sostituisco in  params.py il THRESHOLD_JOBS --> $3\n"
#sed -i "72s/.*/THRESHOLD_JOBS = $3/" "$PWD/scripts/params.py"


printf "testo il Makefile e lo copio se serve nella posizione $1\n"
MAKE_FILE="$1/Makefile"
if test -f "$MAKE_FILE"; then  #se il file esiste allora
	if ! grep "golden" $MAKE_FILE; then #se il file non ha comandi golden allora
	echo "golden:
	./$2 >golden_stdout.txt 2>golden_stderr.txt" >> $MAKE_FILE #scrivo il comando golden
	fi
else 
	cp "/$PWD/pattern/Makefile" "$1" #se non esiste il makefile provvedo 
	sed -i "s/app_name/$2/g" $MAKE_FILE
fi

cd $1
printf "entro e make di $1\n"
#make clean
make 2> stderr.txt
make golden

cd $CWD
printf "ritorno a $CWD\n"

cd scripts/
printf "\nStep 1 (1): Profile the application\n"
printf "run_profiler in AZIONE\n"
python run_profiler.py clean
rm -f stdout.txt stderr.txt ### cleanup
cd -

cd scripts/
printf "\nStep 1 (2): Generate injection list for instruction-level error injections\n"
python generate_injection_list.py 


################################################
# Step 2: Run the error injection campaign 
################################################
printf "\nStep 2: Run the error injection campaign"
python run_injections.py standalone  # to run the injection campaign on a single machine with single gpu

################################################
# Step 3: Parse the results
################################################
printf "\nStep 3: Parse results"
python parse_results.py
