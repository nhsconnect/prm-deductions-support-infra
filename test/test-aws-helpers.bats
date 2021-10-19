#!/usr/bin/env bats

setup() {
    load 'helpers/bats-support/load'
    load 'helpers/bats-assert/load'
}

@test 'simple passing test' {
    run echo 'bob'
    assert_output 'bob'
}

@test 'simple failing test' {
    run echo 'sue'
    assert_failure
}

@test 'can run _assume_environment_role even if aws not found' {
    source utils/aws-helpers
    run _assume_environment_role
    assert_output --partial "aws: command not found"
}
