#!/usr/bin/env bats

setup() {
    load 'helpers/bats-support/load'
    load 'helpers/bats-assert/load'

    rm -f calls.txt

    source utils/aws-helpers
}

stub_role_lookup() {
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
    grep $required_call calls.txt
}

spy_on() {
    fn_name=$1
    eval "$fn_name() { log_call '$fn_name'; }"
}

@test '_assume_environment_role uses ci agent roles if current identity is ci account gocd agent' {

    stub_role_lookup 'arn:aws:iam::1234567890:assumed-role/gocd_agent-prod/12345'

    spy_on 'assume_role_for_ci_agent'

    run _assume_environment_role

    assert was_called 'assume_role_for_ci_agent'
}

@test '_assume_environment_role uses ci agent roles if current identity is environment account agent role' {

    stub_role_lookup 'arn:aws:iam::1234567890:assumed-role/repository-ci-agent/12345'

    spy_on 'assume_role_for_ci_agent'

    run _assume_environment_role

    assert was_called 'assume_role_for_ci_agent'
}

@test '_assume_environment_role uses user roles if current identity is a user' {

    stub_role_lookup 'arn:aws:iam::1234567890:user/jo.bloggs1'

    spy_on 'assume_role_for_user'

    run _assume_environment_role

    assert was_called 'assume_role_for_user'
}

