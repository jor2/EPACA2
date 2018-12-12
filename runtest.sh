#!/bin/bash

# Store filenames in variables for reusability/ensures consitency.
results=./results.dat
cleanup=./cleanup.sh
stats=./stats.txt
loadtest=./loadtest
synthetic=./synthetic.dat
csv=./results.csv

# If a previous run was made it will clean up the previously made files
# for the current run, instead of appending to those files.
# Does this by checking if ./results.dat file exists. If not, ignore.
if [ -e "$results" ]; then
    echo "Cleaning up from previous run..."
	# Calls cleanup script that just removes the previously made files.
	# This was useful in the testing of my application as I didn't have
	# to constantly clean up from previous runs as the task was automated.
	$cleanup
fi 

# Just some output to give some understanding to the user, so as they have
# an idea of what is happening under the hood.
# Felt like it made my script a little bit prettier :)
echo "Will now begin to run ${loadtest##*/}, please wait..."
echo "###################################################"
# ${results##*/} returns only the filename from the results variable declared
# at the beginning of my script e.g "Output from results.dat".
echo "#             Output from ${results##*/}             #"
echo "###################################################"

# Just adds the headers C0, N, and idle to my results file.
printf "C0\tN\tidle\n" >> $results
cat $results
# For loop as instructed in the document to loop through script from 1 to 50.
for i in {1..50}
do
	# timeout n so the script will only run for n seconds before it times out.
	# Runs the script ./loadtest stored in the loadtest variable with param
	# specified by the index of the for loop, i, e.g. ./loadtest 1 then 2, 3 etc.
	# Runs the mpstat command and stores the results from the command in the
	# stats file (./stats.txt)
	timeout 2 $loadtest $i | mpstat 1 1 >> $stats

	# Creates variable c0 that stores the current value of that column during
	# this run. This value is the number of lines contained in the synthetic.dat
	# file, i.e. number of transactions completed.
	c0=`cat $synthetic | wc -l`
	# Uses printf so I can tab etc.
	# Puts variable held in c0 and i into results.dat in format "24 	3   	"
	printf "$c0\t$i\t" >> $results

	# Using awk I can retrieve the value of the 12th header (idle).
	# But because multiple results of mpstat are held in the stats file I need
	# to only take the last results, which would be the latest result of mpstat
	# that was appended into the stats file.
	awk '{print $12}' $stats | tail -n1 >> $results | tr -d '\n'
	# Just to give continious output to the user so they know the script is 
	# indeed running correctly.
	cat $results | tail -n1
done

cat $results >> $csv