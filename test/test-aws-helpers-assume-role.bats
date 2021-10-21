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

it=_assume_environment_role

@test '$it uses ci agent roles if current identity is the ci account gocd agent' {
    stub_current_identity 'arn:aws:iam::blah-account:assumed-role/gocd_agent-prod/blah-session'
    spy_on 'assume_role_for_ci_agent'

    run _assume_environment_role

    assert was_called 'assume_role_for_ci_agent'
}

@test '$it assumes env Deployer role when assuming role as gocd agent' {
    stub_current_identity 'arn:aws:iam::blah-account:assumed-role/gocd_agent-prod/blah-session'

    run _assume_environment_role

    assert_output --partial 'Assuming Deployer'
}

@test '$it uses ci agent roles if current identity is the env account Deployer, needed for scripted docker promotion' {
    stub_current_identity 'arn:aws:iam::blah-account:assumed-role/Deployer/blah-session'
    spy_on 'assume_role_for_ci_agent'

    run _assume_environment_role

    assert was_called 'assume_role_for_ci_agent'
}

@test '$it assumes target env Deployer role when assuming role as another env Deployer for promotion purposes' {
    stub_current_identity 'arn:aws:iam::blah-account:assumed-role/Deployer/blah-session'

    run _assume_environment_role

    assert_output --partial 'Assuming Deployer'
}

@test '$it prompts users to assume broad-access RepoAdmin role directly in dev and exits' {
    stub_current_identity 'arn:aws:iam::blah-account:user/jo.bloggs1'

    exit_code_users_should_assume_role_first=7

    run _assume_environment_role dev

    assert_output --partial 'Please assume RepoAdmin in dev directly from your shell'
    refute_output --partial 'Assuming RepoAdmin'
    assert_equal $status $exit_code_users_should_assume_role_first
}

@test '$it prompts users to assume broad-access RepoAdmin role directly in test account and exits' {
    stub_current_identity 'arn:aws:iam::blah-account:user/ham.solo1'

    run _assume_environment_role test

    assert_output --partial 'Please assume RepoAdmin in test directly from your shell'
    refute_output --partial 'Assuming'
    assert_failure
}

@test '$it prompts users to assume strict RepoDeveloper role directly in pre-prod and exits' {
    stub_current_identity 'arn:aws:iam::blah-account:user/jack.frost1'

    run _assume_environment_role pre-prod

    assert_output --partial 'Please assume RepoDeveloper in pre-prod directly from your shell'
    refute_output --partial 'Assuming'
    assert_failure
}

@test '$it prompts users to assume strict RepoDeveloper role directly in prod and exits' {
    stub_current_identity 'arn:aws:iam::blah-account:user/loopy.liu1'

    run _assume_environment_role prod

    assert_output --partial 'Please assume RepoDeveloper in prod directly from your shell'
    refute_output --partial 'Assuming'
    assert_failure
}

@test '$it prompts users to assume strict BootstrapAdmin role directly in pre-prod and exits' {
    stub_current_identity 'arn:aws:iam::blah-account:user/loopy.liu1'

    is_bootstrap_admin=true
    run _assume_environment_role pre-prod $is_bootstrap_admin

    assert_output --partial 'Please assume BootstrapAdmin in pre-prod directly from your shell'
    refute_output --partial 'Assuming'
    assert_failure
}

@test '$it prompts users to assume strict BootstrapAdmin role directly in prod and exits' {
    stub_current_identity 'arn:aws:iam::blah-account:user/loopy.liu1'

    is_bootstrap_admin=true
    run _assume_environment_role prod $is_bootstrap_admin

    assert_output --partial 'Please assume BootstrapAdmin in prod directly from your shell'
    refute_output --partial 'Assuming'
    assert_failure
}

@test '$it uses user roles if they have already assumed env RepoAdmin role' {
    stub_current_identity 'arn:aws:iam::blah-account:assumed-role/RepoAdmin/blah-session'

    spy_on 'assume_role_for_user'

    run _assume_environment_role

    assert was_called 'assume_role_for_user'
}

@test '$it does not attempt to assume role if user is already in RepoAdmin role in dev' {
    stub_current_identity 'arn:aws:iam::blah-account:assumed-role/RepoAdmin/blah-session'

    run _assume_environment_role dev

    refute_output --partial 'Assuming'
}


@test '$it does not attempt to assume role if user is already in RepoAdmin role in test' {
    stub_current_identity 'arn:aws:iam::blah-account:assumed-role/RepoAdmin/blah-session'

    run _assume_environment_role test

    refute_output --partial 'Assuming'
}

@test '$it uses user roles if they have already assumed env BootstrapAdmin role' {
    stub_current_identity 'arn:aws:iam::blah-account:assumed-role/BootstrapAdmin/blah-session'
    spy_on 'assume_role_for_user'

    run _assume_environment_role

    assert was_called 'assume_role_for_user'
}

@test '$it does not attempt to assume role if user is already in BootstrapAdmin role in pre-prod' {
    stub_current_identity 'arn:aws:iam::blah-account:assumed-role/BootstrapAdmin/blah-session'

    run _assume_environment_role pre-prod

    refute_output --partial 'Assuming'
}

@test '$it uses user roles if they have already assumed env RepoDeveloper role' {
    stub_current_identity 'arn:aws:iam::blah-account:assumed-role/RepoDeveloper/blah-session'
    spy_on 'assume_role_for_user'

    run _assume_environment_role

    assert was_called 'assume_role_for_user'
}

@test '$it does not attempt to assume role if user is already in RepoDeveloper role in pre-prod' {
    stub_current_identity 'arn:aws:iam::blah-account:assumed-role/RepoDeveloper/blah-session'

    run _assume_environment_role pre-prod

    refute_output --partial 'Assuming'
}

@test '$it warns users off using NHSDAdminRole if they have assumed it and exits' {
    stub_current_identity 'arn:aws:iam::blah-account:assumed-role/NHSDAdminRole/blah-session'
    exit_code_dont_use_nhsdadminrole=6

    run _assume_environment_role

    assert_output --partial 'assume role direct from your user identity'
    assert_equal $status $exit_code_dont_use_nhsdadminrole
}


@test '$it fails fast if using an unexpected role' {
    stub_current_identity 'arn:aws:iam::blah-account:assumed-role/SomeNonExistentRole/blah-session'
    exit_code_unhandled_identity=18

    run _assume_environment_role

    assert_output --partial 'unhandled identity'
    assert_output --partial 'SomeNonExistentRole'
    assert_equal $status $exit_code_unhandled_identity
}
