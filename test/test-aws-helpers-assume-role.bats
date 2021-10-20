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

@test '_assume_environment_role uses user roles if current identity is a user' {

    stub_current_identity 'arn:aws:iam::blah-account:user/jo.bloggs1'

    spy_on 'assume_role_for_user'

    run _assume_environment_role

    assert was_called 'assume_role_for_user'
}

@test '_assume_environment_role uses user roles if current identity is RepoAdmin role' {

    stub_current_identity 'arn:aws:iam::blah-account:assumed-role/RepoAdmin/blah-session'

    spy_on 'assume_role_for_user'

    run _assume_environment_role

    assert was_called 'assume_role_for_user'
}


