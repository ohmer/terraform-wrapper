SHELL := $(shell env | grep SHELL= | cut -d '=' -f '2' )

python_version_full := $(wordlist 2,4,$(subst ., ,$(shell python3 --version 2>&1)))
python_version_minor := $(word 2,${python_version_full})

makefile_path := $(realpath $(lastword $(MAKEFILE_LIST)))
wrapper_dir := $(patsubst %/,%,$(dir $(makefile_path)))
virtualenv_dir := $(wrapper_dir)/.virtualenv

.DEFAULT_GOAL := work

setup:
ifeq ($(shell test $(python_version_minor) -le 4; echo $$?),0)
	$(error Python 3 too old, use Python 3.5 or greater.)
endif
ifneq ($(shell test -d $(virtualenv_dir); echo $$?),0)
	@echo 'Setting up virtualenv.'
	@virtualenv -p python3 $(virtualenv_dir)
	@$(virtualenv_dir)/bin/pip install -r $(wrapper_dir)/requirements.txt
endif

clear:
	@echo 'Removing virtualenv.'
	@rm -Rf $(virtualenv_dir)

work: setup
	@PATH="$(wrapper_dir)/bin:$(virtualenv_dir)/bin:$(PATH)" $(SHELL)
