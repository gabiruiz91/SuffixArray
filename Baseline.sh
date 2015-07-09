#!/bin/bash

# Free software. By L Ferres, Universidad de Concepcion, Chile

# Some general guidelines for running experiments:
#  * Disable all screen/power saving options
#  * Possibly restart machine before long experiment
#  * Disable Hyperthreading
#  * Close all applications except for a console (e.g. killall -u keira)

# This needs the hwloc tools (uses lstopo)

sleep 10

echo "Running tests... "

start=$(date +"%Y%m%d-%H:%M:%S")

# Column information. Please complete the header of all columns in the
# array below. Do not use spaces or punctuation symbols. Capitalize
# every word for easy human parsing.
Cols=("ExperimentNumber" "Algorithm" "NumberOfThreads" "InputFile"
"LengthOfText" "ElapsedTimeSec" "Instructions" "LLCReadMisses"
"LLCWriteMisses")

numcols=$(echo ${Cols[@]})

Columns=$(echo ${numcols// /,}) # build comma-separated column info

iterations=3
outfile=results$(date +"%Y-%m-%d-%H:%M:%S").data

# Algorithm information: List of implemented string matching
# algorithms
SeqAlgos=()
ParAlgos=("psa")

#SeqAlgos=("rwt" "wt" "wt_no_ptrs" "wt_pepe")
#ParAlgos=("ddrwt" "prwt" "pwt" "pwt_no_ptrs")

numseqalgos=${#SeqAlgos[@]}
numparalgos=${#ParAlgos[@]}


# Experimental trials

Trials=("/home/unsj/datasets/trials/trial.english.32MB.1024"
"/home/unsj/datasets/trials/trial.dna.128MB.1024"
"/home/unsj/datasets/trials/trial.english.32MB.1048576"
"/home/unsj/datasets/trials/trial.dna.128MB.1048576"
"/home/unsj/datasets/trials/trial.english.32MB.32768"
"/home/unsj/datasets/trials/trial.dna.128MB.32768"
"/home/unsj/datasets/trials/trial.english.4MB.1024"
"/home/unsj/datasets/trials/trial.dna.16MB.1024"
"/home/unsj/datasets/trials/trial.english.4MB.1048576"
"/home/unsj/datasets/trials/trial.dna.16MB.1048576"
"/home/unsj/datasets/trials/trial.english.4MB.32768"
"/home/unsj/datasets/trials/trial.dna.16MB.32768"
"/home/unsj/datasets/trials/trial.english.64MB.1024"
"/home/unsj/datasets/trials/trial.dna.1MB.1024"
"/home/unsj/datasets/trials/trial.english.64MB.1048576"
"/home/unsj/datasets/trials/trial.dna.1MB.1048576"
"/home/unsj/datasets/trials/trial.english.64MB.32768"
"/home/unsj/datasets/trials/trial.dna.1MB.32768"
"/home/unsj/datasets/trials/trial.english.8MB.1024"
"/home/unsj/datasets/trials/trial.dna.2MB.1024"
"/home/unsj/datasets/trials/trial.english.8MB.1048576"
"/home/unsj/datasets/trials/trial.dna.2MB.1048576"
"/home/unsj/datasets/trials/trial.english.8MB.32768"
"/home/unsj/datasets/trials/trial.dna.2MB.32768"
"/home/unsj/datasets/trials/trial.proteins.128MB.1024"
"/home/unsj/datasets/trials/trial.dna.32MB.1024"
"/home/unsj/datasets/trials/trial.proteins.128MB.1048576"
"/home/unsj/datasets/trials/trial.dna.32MB.1048576"
"/home/unsj/datasets/trials/trial.proteins.128MB.32768"
"/home/unsj/datasets/trials/trial.dna.32MB.32768"
"/home/unsj/datasets/trials/trial.proteins.16MB.1024"
"/home/unsj/datasets/trials/trial.dna.4MB.1024"
"/home/unsj/datasets/trials/trial.proteins.16MB.1048576"
"/home/unsj/datasets/trials/trial.dna.4MB.1048576"
"/home/unsj/datasets/trials/trial.proteins.16MB.32768"
"/home/unsj/datasets/trials/trial.dna.4MB.32768"
"/home/unsj/datasets/trials/trial.proteins.1MB.1024"
"/home/unsj/datasets/trials/trial.dna.64MB.1024"
"/home/unsj/datasets/trials/trial.proteins.1MB.1048576"
"/home/unsj/datasets/trials/trial.dna.64MB.1048576"
"/home/unsj/datasets/trials/trial.proteins.1MB.32768"
"/home/unsj/datasets/trials/trial.dna.64MB.32768"
"/home/unsj/datasets/trials/trial.proteins.2MB.1024"
"/home/unsj/datasets/trials/trial.dna.8MB.1024"
"/home/unsj/datasets/trials/trial.proteins.2MB.1048576"
"/home/unsj/datasets/trials/trial.dna.8MB.1048576"
"/home/unsj/datasets/trials/trial.proteins.2MB.32768"
"/home/unsj/datasets/trials/trial.dna.8MB.32768"
"/home/unsj/datasets/trials/trial.proteins.32MB.1024"
"/home/unsj/datasets/trials/trial.english.128MB.1024"
"/home/unsj/datasets/trials/trial.proteins.32MB.1048576"
"/home/unsj/datasets/trials/trial.english.128MB.1048576"
"/home/unsj/datasets/trials/trial.proteins.32MB.32768"
"/home/unsj/datasets/trials/trial.english.128MB.32768"
"/home/unsj/datasets/trials/trial.proteins.4MB.1024"
"/home/unsj/datasets/trials/trial.english.16MB.1024"
"/home/unsj/datasets/trials/trial.proteins.4MB.1048576"
"/home/unsj/datasets/trials/trial.english.16MB.1048576"
"/home/unsj/datasets/trials/trial.proteins.4MB.32768"
"/home/unsj/datasets/trials/trial.english.16MB.32768"
"/home/unsj/datasets/trials/trial.proteins.64MB.1024"
"/home/unsj/datasets/trials/trial.english.1MB.1024"
"/home/unsj/datasets/trials/trial.proteins.64MB.1048576"
"/home/unsj/datasets/trials/trial.english.1MB.1048576"
"/home/unsj/datasets/trials/trial.proteins.64MB.32768"
"/home/unsj/datasets/trials/trial.english.1MB.32768"
"/home/unsj/datasets/trials/trial.proteins.8MB.1024"
"/home/unsj/datasets/trials/trial.english.2MB.1024"
"/home/unsj/datasets/trials/trial.proteins.8MB.1048576"
"/home/unsj/datasets/trials/trial.english.2MB.1048576"
"/home/unsj/datasets/trials/trial.proteins.8MB.32768"
"/home/unsj/datasets/trials/trial.english.2MB.32768")

numtrials=${#Trials[@]}

numprocs=$(grep "processor" /proc/cpuinfo | sort -u | wc -l)

#totnumexps=$(echo "${numprocs}*${numseqalgos}*${numtrials}" | bc)

countexps=1

    # Header information
echo "# Generated="$(date +"%Y%m%d-%H:%M:%S")", User="$USER > ${outfile}
echo "# "$(uname -a) >>  ${outfile}
lstopo --no-io --no-bridges - | awk '{print "# " $0}' >> ${outfile}
echo $Columns >> ${outfile}

for (( k=0; k<${numparalgos}; k++)) # iterate over algorithms
do
    for j in 10 8 6 4 2 1  # iterate over processors
#    for j in 12  # iterate over processors
    do
	for (( l=0; l<${numtrials}; l++)) # iterate over trials
	do
	  for (( i=0; i<${iterations}; i++)) # repetitions
	  do
	    echo -n -e "\rExperiment ${countexps}"
	    echo -n $countexps","${ParAlgos[k]}"," >> ${outfile}

	    CILK_NWORKERS=${j} perf stat -o ${outfile}.tmp -x, \
                -e instructions,LLC-load-misses,LLC-store-misses \
		./${ParAlgos[k]} $(cat ${Trials[l]}) >> ${outfile}

	    cut -d, -f1 ${outfile}.tmp | sed '/#/d' | sed '/^$/d' \
                | paste -s | sed 's/\s\+/,/g' >> ${outfile}

            echo -e '$-1s/\\n/,/\nx' | ex ${outfile}
	    
	    countexps=`expr $countexps + 1`
	  done
	done
    done
done

for (( k=0; k<${numseqalgos}; k++)) # iterate over algorithms
do
    for (( l=0; l<${numtrials}; l++)) # iterate over trials
    do
      for (( i=0; i<${iterations}; i++)) # iterate over trials
      do
	echo -n -e "\rExperiment ${countexps}"
	echo -n $countexps","${SeqAlgos[k]}"," >> ${outfile}

	CILK_NWORKERS=${j} perf stat -o ${outfile}.tmp -x, \
            -e instructions,LLC-load-misses,LLC-store-misses \
	    ./${SeqAlgos[k]} $(cat ${Trials[l]}) >> ${outfile}
	
	cut -d, -f1 ${outfile}.tmp | sed '/#/d' | sed '/^$/d' \
            | paste -s | sed 's/\s\+/,/g' >> ${outfile}
	
        echo -e '$-1s/\\n/,/\nx' | ex ${outfile}
	
	countexps=`expr $countexps + 1`
     done
    done
done

rm *.tmp

echo -e "\nDone. (started at: "$start", ended at "$(date +"%Y%m%d-%H:%M:%S")")"
