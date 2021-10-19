#!/usr/bin/env bats

setup() {
    load 'helpers/bats-support/load'
    load 'helpers/bats-assert/load'
}

@test 'simple passing test' {
    run echo 'bob'
    assert_output 'bob'
}

@test 'can run _assume_environment_role but aws will not be found' {
    source utils/aws-helpers
    run _assume_environment_role
    assert_output --partial "aws: command not found"
}
