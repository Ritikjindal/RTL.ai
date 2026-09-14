.DEFAULT_GOAL := all

strategies/mac_unit.valid_reg2/sat/status:
	@echo "Running strategy 'sat' on 'mac_unit.valid_reg2'.."
	@bash -c "cd strategies/mac_unit.valid_reg2/sat; source run.sh"

strategies/mac_unit.valid_reg/sat/status:
	@echo "Running strategy 'sat' on 'mac_unit.valid_reg'.."
	@bash -c "cd strategies/mac_unit.valid_reg/sat; source run.sh"

strategies/mac_unit.sum_reg/sat/status:
	@echo "Running strategy 'sat' on 'mac_unit.sum_reg'.."
	@bash -c "cd strategies/mac_unit.sum_reg/sat; source run.sh"

strategies/mac_unit.sum23/sat/status:
	@echo "Running strategy 'sat' on 'mac_unit.sum23'.."
	@bash -c "cd strategies/mac_unit.sum23/sat; source run.sh"

strategies/mac_unit.sum01/sat/status:
	@echo "Running strategy 'sat' on 'mac_unit.sum01'.."
	@bash -c "cd strategies/mac_unit.sum01/sat; source run.sh"

strategies/mac_unit.sum/sat/status:
	@echo "Running strategy 'sat' on 'mac_unit.sum'.."
	@bash -c "cd strategies/mac_unit.sum/sat; source run.sh"

strategies/mac_unit.prod3/sat/status:
	@echo "Running strategy 'sat' on 'mac_unit.prod3'.."
	@bash -c "cd strategies/mac_unit.prod3/sat; source run.sh"

strategies/mac_unit.prod2/sat/status:
	@echo "Running strategy 'sat' on 'mac_unit.prod2'.."
	@bash -c "cd strategies/mac_unit.prod2/sat; source run.sh"

strategies/mac_unit.prod1/sat/status:
	@echo "Running strategy 'sat' on 'mac_unit.prod1'.."
	@bash -c "cd strategies/mac_unit.prod1/sat; source run.sh"

strategies/mac_unit.prod0/sat/status:
	@echo "Running strategy 'sat' on 'mac_unit.prod0'.."
	@bash -c "cd strategies/mac_unit.prod0/sat; source run.sh"

strategies/mac_unit.b_reg/sat/status:
	@echo "Running strategy 'sat' on 'mac_unit.b_reg'.."
	@bash -c "cd strategies/mac_unit.b_reg/sat; source run.sh"

strategies/mac_unit.acc_valid/sat/status:
	@echo "Running strategy 'sat' on 'mac_unit.acc_valid'.."
	@bash -c "cd strategies/mac_unit.acc_valid/sat; source run.sh"

strategies/mac_unit.acc/sat/status:
	@echo "Running strategy 'sat' on 'mac_unit.acc'.."
	@bash -c "cd strategies/mac_unit.acc/sat; source run.sh"

strategies/mac_unit.a_reg/sat/status:
	@echo "Running strategy 'sat' on 'mac_unit.a_reg'.."
	@bash -c "cd strategies/mac_unit.a_reg/sat; source run.sh"

.PHONY: all summary
all: strategies/mac_unit.a_reg/sat/status strategies/mac_unit.acc/sat/status strategies/mac_unit.acc_valid/sat/status strategies/mac_unit.b_reg/sat/status strategies/mac_unit.prod0/sat/status strategies/mac_unit.prod1/sat/status strategies/mac_unit.prod2/sat/status strategies/mac_unit.prod3/sat/status strategies/mac_unit.sum/sat/status strategies/mac_unit.sum01/sat/status strategies/mac_unit.sum23/sat/status strategies/mac_unit.sum_reg/sat/status strategies/mac_unit.valid_reg/sat/status strategies/mac_unit.valid_reg2/sat/status
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
