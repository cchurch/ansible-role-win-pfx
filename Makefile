.PHONY: core-requirements
core-requirements:
	pip install pip setuptools "pip-tools>=1"

.PHONY: update-pip-requirements
update-pip-requirements: core-requirements
	pip install -U pip setuptools "pip-tools>=1"
	pip-compile -U requirements.in

.PHONY: requirements
requirements: core-requirements
	pip-sync requirements.txt

.PHONY: syntax-check
syntax-check: requirements
	ANSIBLE_CONFIG=tests/ansible.cfg ansible-playbook -i tests/inventory tests/main.yml --syntax-check

.PHONY: clean-tox
clean-tox:
	rm -rf .tox

.PHONY: tox
tox: requirements
	tox

.PHONY: lint
lint: requirements
	ansible-lint tests/main.yml

.PHONY: bump-major
bump-major: requirements
	bumpversion major

.PHONY: bump-minor
bump-minor: requirements
	bumpversion minor

.PHONY: bump-patch
bump-patch: requirements
	bumpversion patch
