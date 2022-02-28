#!/usr/bin/env bats

setup() {
    load 'helpers/bats-support/load'
    load 'helpers/bats-assert/load'
}

mask_pii_from_input() {
  input=$1
  output=$(echo $input | ./utils/mask-pii.sh)
  echo $output
}

@test '$it should mask 10 digit number' {
    input='0123456789'
    mask_pii_from_input "$input"

    assert_output '##########'
}

@test '$it should mask 10 digit number in quotes' {
    input='"0123456789"'
    mask_pii_from_input "$input"

    assert_output '"##########"'
}

@test '$it should mask 10 digit from json string' {
    input='{"nhsNumber":"0123456789"}'
    mask_pii_from_input "$input"

    assert_output '{"nhsNumber":"##########"}'
}

@test '$it should mask 10 digit url string' {
    input='patient-number/0123456789'
    mask_pii_from_input "$input"

    assert_output 'patient-number/##########'
}

@test '$it should mask multiple 10 digit numbers' {
    input='0123456789 0987654321'
    mask_pii_from_input "$input"

    assert_output '########## ##########'
}

@test '$it should mask multiple 10 digit numbers in string' {
    input='0123456789 this is 10 digits and this 0011223344 and this9999999999this 8888888888'
    mask_pii_from_input "$input"

    assert_output '########## this is 10 digits and this ########## and this##########this ##########'
}

@test '$it should not mask less than 10 digit numbers' {
    input='012345678'
    mask_pii_from_input "$input"

    assert_output '012345678'
}

@test '$it should not mask more than 10 digit numbers' {
    input='01234567899'
    mask_pii_from_input "$input"

    assert_output '01234567899'
}
