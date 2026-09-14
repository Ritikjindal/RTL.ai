.DEFAULT_GOAL := all

strategies/bm_mac8.vld/sat/status:
	@echo "Running strategy 'sat' on 'bm_mac8.vld'.."
	@bash -c "cd strategies/bm_mac8.vld/sat; source run.sh"

strategies/bm_mac8.out_valid/sat/status:
	@echo "Running strategy 'sat' on 'bm_mac8.out_valid'.."
	@bash -c "cd strategies/bm_mac8.out_valid/sat; source run.sh"

strategies/bm_mac8.m7/sat/status:
	@echo "Running strategy 'sat' on 'bm_mac8.m7'.."
	@bash -c "cd strategies/bm_mac8.m7/sat; source run.sh"

strategies/bm_mac8.m6/sat/status:
	@echo "Running strategy 'sat' on 'bm_mac8.m6'.."
	@bash -c "cd strategies/bm_mac8.m6/sat; source run.sh"

strategies/bm_mac8.m5/sat/status:
	@echo "Running strategy 'sat' on 'bm_mac8.m5'.."
	@bash -c "cd strategies/bm_mac8.m5/sat; source run.sh"

strategies/bm_mac8.m4/sat/status:
	@echo "Running strategy 'sat' on 'bm_mac8.m4'.."
	@bash -c "cd strategies/bm_mac8.m4/sat; source run.sh"

strategies/bm_mac8.m3/sat/status:
	@echo "Running strategy 'sat' on 'bm_mac8.m3'.."
	@bash -c "cd strategies/bm_mac8.m3/sat; source run.sh"

strategies/bm_mac8.m2/sat/status:
	@echo "Running strategy 'sat' on 'bm_mac8.m2'.."
	@bash -c "cd strategies/bm_mac8.m2/sat; source run.sh"

strategies/bm_mac8.m1/sat/status:
	@echo "Running strategy 'sat' on 'bm_mac8.m1'.."
	@bash -c "cd strategies/bm_mac8.m1/sat; source run.sh"

strategies/bm_mac8.m0/sat/status:
	@echo "Running strategy 'sat' on 'bm_mac8.m0'.."
	@bash -c "cd strategies/bm_mac8.m0/sat; source run.sh"

strategies/bm_mac8.b_reg/sat/status:
	@echo "Running strategy 'sat' on 'bm_mac8.b_reg'.."
	@bash -c "cd strategies/bm_mac8.b_reg/sat; source run.sh"

strategies/bm_mac8.acc/sat/status:
	@echo "Running strategy 'sat' on 'bm_mac8.acc'.."
	@bash -c "cd strategies/bm_mac8.acc/sat; source run.sh"

strategies/bm_mac8.a_reg/sat/status:
	@echo "Running strategy 'sat' on 'bm_mac8.a_reg'.."
	@bash -c "cd strategies/bm_mac8.a_reg/sat; source run.sh"

.PHONY: all summary
all: strategies/bm_mac8.a_reg/sat/status strategies/bm_mac8.acc/sat/status strategies/bm_mac8.b_reg/sat/status strategies/bm_mac8.m0/sat/status strategies/bm_mac8.m1/sat/status strategies/bm_mac8.m2/sat/status strategies/bm_mac8.m3/sat/status strategies/bm_mac8.m4/sat/status strategies/bm_mac8.m5/sat/status strategies/bm_mac8.m6/sat/status strategies/bm_mac8.m7/sat/status strategies/bm_mac8.out_valid/sat/status strategies/bm_mac8.vld/sat/status
	$(MAKE) -f strategies.mk summary
summary:
	@rc=0 ; \
	while read f; do \
		p=$${f#strategies/} ; p=$${p%/*/status} ; \
		if grep -q "PASS" $$f ; then \
			echo "* Successfully proved equivalence of partition $$p" ; \
		else \
			echo "* Failed to prove equivalence of partition $$p" ; rc=1 ; \
		fi ; \
	done < summary_targets.list ; \
	if [ "$$rc" -eq 0 ] ; then \
		echo "* Successfully proved designs equivalent" ; \
	fi
