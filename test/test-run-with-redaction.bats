#!/usr/bin/env bats

setup() {
    load 'helpers/bats-support/load'
    load 'helpers/bats-assert/load'
}

echo_with_redaction() {
  input=$1
  output=$(./utils/run-with-redaction.sh echo $input | grep -v 'Running command')
}

@test '$it should mask 10 digit number' {
    input='0123456789'
    echo_with_redaction "$input"

    assert_output '##########'


}

@test '$it should mask 10 digit number in quotes' {
    input='"0123456789"'
    echo_with_redaction "$input"

    assert_output '"##########"'
}

@test '$it should mask 10 digit from json string' {
    input='{"nhsNumber":"0123456789"}'
    echo_with_redaction "$input"

    assert_output '{"nhsNumber":"##########"}'
}

@test '$it should mask 10 digit url string' {
    input='patient-number/0123456789'
    echo_with_redaction "$input"

    assert_output 'patient-number/##########'
}

@test '$it should mask multiple 10 digit numbers' {
    input='0123456789 0987654321'
    echo_with_redaction "$input"

    assert_output '########## ##########'
}

@test '$it should mask multiple 10 digit numbers in string' {
    input='0123456789 this is 10 digits and this 0011223344 and this9999999999this 8888888888'
    echo_with_redaction "$input"

    assert_output '########## this is 10 digits and this ########## and this##########this ##########'
}

@test '$it should not mask less than 10 digit numbers' {
    input='012345678'
    echo_with_redaction "$input"

    assert_output '012345678'
}

@test '$it should not mask more than 10 digit numbers' {
    input='01234567899'
    echo_with_redaction "$input"

    assert_output '01234567899'
}
