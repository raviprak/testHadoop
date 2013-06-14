#!/bin/bash

#Print usage if the arguments to the program are wrong
if [[ 3 -lt 2 || ( "$1" != "ant" && "$1" != "mvn" ) ]]; then
	echo -e "Usage: \n	testHadoop.sh ant|mvn <testname> [maxcount]"
	exit 1
fi

METHOD=$1	# Wether its an ant test or mvn
TESTNAME=$2	# Name of the test
MAXCOUNT=$3	# The number of times the test will be repeated
if [ -z $MAXCOUNT ]; then
	MAXCOUNT=100	# default MAXCOUNT to 100
fi

echo Testing $TESTNAME using $METHOD a total of $MAXCOUNT times
COUNT=1		# The number of times the test has been run
PASSCOUNT=0	# The number of times the test has passed
FAILCOUNT=0	# The number of times the test has failed

# Make the directory into which we will write the ant/mvn command output
mkdir -p /tmp/testHadoop/${TESTNAME}


while [ $COUNT -lt $MAXCOUNT ]; do
	STARTTIME=`date +%s`	# Note the start time because we will be printing out the time it took to run the test

	# Run the test. Redirect stderr and stdout to an .inProgress file
	if [ "$METHOD" == "ant" ]; then
		ant -Dtestcase=${TESTNAME} test &> /tmp/testHadoop/${TESTNAME}.${COUNT}.inProgress
	else
		mvn -Dtest=${TESTNAME} test &> /tmp/testHadoop/${TESTNAME}.${COUNT}.inProgress
	fi
	ENDTIME=`date +%s`

	# If the test was not run, then something is wrong (either the command or the testname). Exit
	if [ -z "`grep "Running" /tmp/testHadoop/${TESTNAME}.${COUNT}.inProgress | grep ${TESTNAME}`" ]; then
		echo "ERROR!! Didn't run the test you had mentioned. Exiting"
		# Move the .inProgress file to a .didntrun file
		mv /tmp/testHadoop/${TESTNAME}.${COUNT}.inProgress /tmp/testHadoop/$TESTNAME/${TESTNAME}.${COUNT}.didntrun
		exit 1
	fi

	# Check wether the test passed or failed
	if [ -n "`grep "\[junit\] Running" /tmp/testHadoop/${TESTNAME}.${COUNT}.inProgress -A 1 | grep ${TESTNAME} -A 1 | grep "Failures: 0, Errors: 0"`" ]; then
		let PASSCOUNT++
		STATUS="passed"
	else
		let FAILCOUNT++
		STATUS="failed"
	fi
	# Echo summary till now
	echo "Attempt $COUNT. Test $TESTNAME ${STATUS}. PassCount: ${PASSCOUNT}. FailCount: ${FAILCOUNT}. Took " `expr $ENDTIME - $STARTTIME` " seconds"
	# Move .inProgress file to the test's directory
	mv /tmp/testHadoop/${TESTNAME}.${COUNT}.inProgress /tmp/testHadoop/$TESTNAME/${TESTNAME}.${COUNT}.${STATUS}
	# Move the TEST-OUTPUT files to a subdirectory
	mkdir /tmp/testHadoop/$TESTNAME/$TESTNAME.${COUNT}.${STATUS}.files
	find . -name "TEST*${TESTNAME}*" | xargs -I{} mv {} /tmp/testHadoop/$TESTNAME/$TESTNAME.${COUNT}.${STATUS}.files
	let COUNT++
done
