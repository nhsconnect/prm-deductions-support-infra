#!/usr/bin/env bats

setup() {
    load 'helpers/bats-support/load'
    load 'helpers/bats-assert/load'
    load 'helpers/bats-mock/stub'

    stub aws
}

teardown() {
    unstub aws || true
}

@test 'can run _assume_environment_role stubbing aws command' {
    source utils/aws-helpers

    run _assume_environment_role
    refute_output --partial "aws: command not found"
}
