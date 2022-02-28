### 0.2.22 (2022-Feb-28)

Switch to statically linked `redactor`.

### 0.2.21 (2022-Feb-28)

Release the glibc-based `redactor` not the musl one built by default on alpine.

### 0.2.20 (2022-Feb-28)

Added redaction utils to release:
* `run-with-redaction.sh` - top level script
* `redactor` - redaction filter binary

### 0.2.19 (2022-Feb-09)

Allow lower assume role auth duration for testing. Set `ASSUME_ROLE_DURATION` var to number of seconds - min 900.

### 0.2.18 (2021-Nov-03)

Introduced image promotion from pre-prod to prod

### 0.2.17 (2021-Oct-21)

If currently a Deployer, attempt to assume new env role as another Deployer, for the
purposes of docker promotion process.

### 0.2.16 (2021-Oct-21)

Ensure default case for assume env role with debug logging.

### 0.2.15 (2021-Oct-21)

Fully switched over to new simplified scheme.
Now use renamed Deployer role for ci agent deploying into envs (was repository-ci-agent).

### 0.2.14 (2021-Oct-21)

Ensure don't try and perform scripted assume-roles for users, just
prompt them appropriately.

### 0.2.13 (2021-Oct-20)

Fixes

### 0.2.12 (2021-Oct-20)

Now prompting users to assume initial environment role directly

Added bats tests for assume role logic

### 0.2.11 (2021-Oct-14)

Changed to assume roles direct from user account

Fixed typo bug on bootstrap admin assume role 

### 0.2.10 (2021-Oct-06)

### 0.2.9 (2021-Jul-28)

### 0.2.8 (2021-Jul-27)

Fixed get_ssm_param script.

### 0.2.7 (2021-Jul-26)

Adopted new pre-prod roles

### 0.2.6 (2021-Jul-19)

Logged the latest released version of the helpers in tasks

### 0.2.5 (2021-Jul-16)
### 0.2.4 (2021-Jul-16)
### 0.2.3 (2021-Jul-16)

### 0.2.2 (2021-Jul-13)

Adopted promote-docker-image script to work in pre-prod
Fixed logs

### 0.2.1 (2021-Jun-08)

Fixed `assume_environment_role` to work for developers.

### 0.2.0 (2021-Jun-04)

Replaced `assume_ci_agent_role` by `assume_environment_role`.
Now assume_environment_role can be used by ci agent or developers in any environment.

### 0.1.2 (2021-May-27)
Fixed promote-docker-image function to not rely on IMAGE_REPO_NAME

### 0.1.1 (2021-May-27)

Fixed publish task

### 0.1.0 (2021-May-27)

First release of aws-helpers script
