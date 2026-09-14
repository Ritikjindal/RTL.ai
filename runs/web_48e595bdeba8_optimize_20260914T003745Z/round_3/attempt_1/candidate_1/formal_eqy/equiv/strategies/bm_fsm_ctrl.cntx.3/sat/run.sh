yosys -ql run.log run.ys
if grep "SAT temporal induction proof finished - model found for base case: FAIL!" run.log > /dev/null ; then
	echo FAIL > status
	echo "Could not prove equivalence of partition 'bm_fsm_ctrl.cntx.3' using strategy 'sat': partitions not equivalent"
elif grep "Reached maximum number of time steps -> proof failed." run.log > /dev/null ; then
	echo UNKNOWN > status
	echo "Could not prove equivalence of partition 'bm_fsm_ctrl.cntx.3' using strategy 'sat': equivalence unknown"
elif grep "Interrupted SAT solver: TIMEOUT!" run.log > /dev/null ; then
	echo UNKNOWN > status
	echo "Could not prove equivalence of partition 'bm_fsm_ctrl.cntx.3' using strategy 'sat': timeout"
elif grep "Induction step proven: SUCCESS!" run.log > /dev/null ; then
	echo PASS > status
	echo "Proved equivalence of partition 'bm_fsm_ctrl.cntx.3' using strategy 'sat'"
else
	echo ERROR > status
	echo "Execution of strategy 'sat' on partition 'bm_fsm_ctrl.cntx.3' encountered an error.
Details can be found in 'equiv/strategies/bm_fsm_ctrl.cntx.3/sat/run.log'."
	exit 1
fi
exit 0

