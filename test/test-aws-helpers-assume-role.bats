#!/usr/bin/env bats

setup() {
    load 'helpers/bats-support/load'
    load 'helpers/bats-assert/load'

    rm -f calls.txt

    source utils/aws-helpers
}

stub_current_identity() {
    role=$1

    aws() {
        echo dummy_aws_output
    }

    jq() {
        read stdinput        # echo $stdinput
        echo $role
    }
}

log_call() {
    function_called=$1
    echo $function_called >> calls.txt
}

was_called() {
    required_call=$1
    if grep $required_call calls.txt 2> /dev/null; then
        echo "$required_call was called"
        return 0
    else
        echo "$required_call was not called"
        return 1
    fi
}

spy_on() {
    fn_name=$1
    eval "$fn_name() { log_call '$fn_name'; }"
}

@test '_assume_environment_role uses ci agent roles if current identity is the ci account gocd agent' {
    stub_current_identity 'arn:aws:iam::blah-account:assumed-role/gocd_agent-prod/blah-session'
    spy_on 'assume_role_for_ci_agent'

    run _assume_environment_role

    assert was_called 'assume_role_for_ci_agent'
}

@test '_assume_environment_role uses ci agent roles if current identity is  the environment account agent role' {
    stub_current_identity 'arn:aws:iam::blah-account:assumed-role/repository-ci-agent/blah-session'
    spy_on 'assume_role_for_ci_agent'

    run _assume_environment_role

    assert was_called 'assume_role_for_ci_agent'
}

@test '_assume_environment_role prompts users to assume broad-access RepoAdmin role directly in dev' {
    stub_current_identity 'arn:aws:iam::blah-account:user/jo.bloggs1'

    run _assume_environment_role dev

    assert_output --partial 'Please assume RepoAdmin in dev directly from your shell'
    refute_output --partial 'Assuming RepoAdmin'
}

@test '_assume_environment_role prompts users to assume broad-access RepoAdmin role directly in test account' {
    stub_current_identity 'arn:aws:iam::blah-account:user/ham.solo1'

    run _assume_environment_role test

    assert_output --partial 'Please assume RepoAdmin in test directly from your shell'
    refute_output --partial 'Assuming'
}

@test '_assume_environment_role prompts users to assume strict RepoDeveloper role directly in pre-prod' {
    stub_current_identity 'arn:aws:iam::blah-account:user/jack.frost1'

    run _assume_environment_role pre-prod

    assert_output --partial 'Please assume RepoDeveloper in pre-prod directly from your shell'
    refute_output --partial 'Assuming'
}

@test '_assume_environment_role prompts users to assume strict RepoDeveloper role directly in prod' {
    stub_current_identity 'arn:aws:iam::blah-account:user/loopy.liu1'

    run _assume_environment_role prod

    assert_output --partial 'Please assume RepoDeveloper in prod directly from your shell'
    refute_output --partial 'Assuming'
}

@test '_assume_environment_role prompts users to assume strict BootstrapAdmin role directly in pre-prod' {
    stub_current_identity 'arn:aws:iam::blah-account:user/loopy.liu1'

    is_bootstrap_admin=true
    run _assume_environment_role pre-prod $is_bootstrap_admin

    assert_output --partial 'Please assume BootstrapAdmin in pre-prod directly from your shell'
    refute_output --partial 'Assuming'
}

@test '_assume_environment_role prompts users to assume strict BootstrapAdmin role directly in prod' {
    stub_current_identity 'arn:aws:iam::blah-account:user/loopy.liu1'

    is_bootstrap_admin=true
    run _assume_environment_role prod $is_bootstrap_admin

    assert_output --partial 'Please assume BootstrapAdmin in prod directly from your shell'
    refute_output --partial 'Assuming'
}

@test '_assume_environment_role uses user roles if current identity is RepoAdmin role' {
    stub_current_identity 'arn:aws:iam::blah-account:assumed-role/RepoAdmin/blah-session'

    spy_on 'assume_role_for_user'

    run _assume_environment_role

    assert was_called 'assume_role_for_user'
}

@test '_assume_environment_role uses user roles if current identity is BootstrapAdmin role' {
    stub_current_identity 'arn:aws:iam::blah-account:assumed-role/BootstrapAdmin/blah-session'
    spy_on 'assume_role_for_user'

    run _assume_environment_role

    assert was_called 'assume_role_for_user'
}

@test '_assume_environment_role uses user roles if current identity is RepoDeveloper role' {
    stub_current_identity 'arn:aws:iam::blah-account:assumed-role/RepoDeveloper/blah-session'
    spy_on 'assume_role_for_user'

    run _assume_environment_role

    assert was_called 'assume_role_for_user'
}

@test '_assume_environment_role displays helpful message if attempting to use from NHSDAdminRole' {
    stub_current_identity 'arn:aws:iam::blah-account:assumed-role/NHSDAdminRole/blah-session'

    run _assume_environment_role

    assert_output --partial 'assume role direct from your user identity'
}
