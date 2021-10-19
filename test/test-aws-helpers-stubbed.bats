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
        # echo 'aws called' >> aws_calls.txt
        # echo $@ >> aws_calls.txt
        
        echo dummy_aws_output
    }

    jq() {
        read stdinput

        # echo 'jq called with stdin' >> jq_calls.txt
        # echo $stdinput >> jq_calls.txt
        # echo $@ >> jq_calls.txt

        echo $role
    }
}

log_call() {
    function_called=$1
    echo $function_called >> calls.txt
}
called() {
    required_call=$1
    grep $required_call calls.txt
}

@test '_assume_environment_role calls assume_role_for_ci_agent if current identity is gocd agent' {

    stub_role_lookup 'arn:aws:iam::1234567890:assumed-role/gocd_agent-prod/12345'

    assume_role_for_ci_agent() {
        log_call 'assume_role_for_ci_agent'
    }

    run _assume_environment_role

    assert called 'assume_role_for_ci_agent'
}

@test '_assume_environment_role calls assume_role_for_ci_agent if current identity is environment account agent role' {

    stub_role_lookup 'arn:aws:iam::1234567890:assumed-role/repository-ci-agent/12345'

    assume_role_for_ci_agent() {
        log_call 'assume_role_for_ci_agent'
    }

    run _assume_environment_role

    assert called 'assume_role_for_ci_agent'
}

@test '_assume_environment_role calls assume_role_for_user if current identity is a user' {

    stub_role_lookup 'arn:aws:iam::1234567890:user/jo.bloggs1'

    assume_role_for_user() {
        log_call 'assume_role_for_user'
    }

    run _assume_environment_role

    assert called 'assume_role_for_user'
}
