# PRM Deductions Support Infrastructure

This is the minimal, very first setup of terraform backend in S3 and DynamoDB.

The terraform state produced in this repository is pushed to a separate bucket with AWS CLI.

To deploy infrastructure, run the following commands:

``` terraform init ```

``` terraform apply ```

Please note the terraform state is local.

## Utility scripts

Folder `utils` contains common scripts to be used across projects.

## Access to AWS

In order to get sufficient access to work with terraform or AWS CLI:

Make sure to unset the AWS variables:
```
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN
```

As a note, the following set-up is based on the README of assume-role [tool](https://github.com/remind101/assume-role)

Set up a profile for each role you would like to assume in `~/.aws/config`, for example:

```
[profile default]
region = eu-west-2
output = json

[profile admin]
region = eu-west-2
role_arn = <role-arn>
mfa_serial = <mfa-arn>
source_profile = default
```

The `source_profile` needs to match your profile in `~/.aws/credentials`.
```
[default]
aws_access_key_id = <your-aws-access-key-id>
aws_secret_access_key = <your-aws-secret-access-key>
```

### Assume role with elevated permissions 

#### Install `assume-role` locally:
`brew install remind101/formulae/assume-role`

Run the following command with the profile configured in your `~/.aws/config`:

`assume-role admin`

#### Run `assume-role` with dojo:
Run the following command with the profile configured in your `~/.aws/config`:

`eval $(dojo "echo <mfa-code> | assume-role admin"`

Run the following command to confirm the role was assumed correctly:

`aws sts get-caller-identity`


## Generating certificates

Export your AWS credentials in shell (if you have credentials in `~/.aws/credentials` that will work too):
```
export AWS_ACCESS_KEY_ID=<your-aws-access-key-id>
export AWS_SECRET_ACCESS_KEY=<your-aws-secret-access-key>
unset AWS_SESSION_TOKEN
```

Enter docker container with openssl and AWS CLI by typing:

`dojo`

at the root of this repository.

To issue certificates for `example.dev.patient-deductions.nhs.uk` run

```
./utils/generate-certs.sh -f example.dev -d example.dev.patient-deductions.nhs.uk
```

The files matching pattern of `example.dev*` will be generated in `./utils/site-certs/*`. 

## AWS SSM Parameters Design Principles

When creating the new ssm keys, please follow the agreed convention as per the design specified below:

* all parts of the keys are lower case
* the words are separated by dashes (`kebab case`)
* `env` is optional
  
### Design:
Please follow this design to ensure the ssm keys are easy to maintain and navigate through:

| Type               | Design                                  | Example                                               |
| -------------------| ----------------------------------------| ------------------------------------------------------|
| **User-specified** |`/repo/<env>?/user-input/`               | `/repo/${var.environment}/user-input/db-username`     |
| **Auto-generated** |`/repo/<env>?/output/<name-of-git-repo>/`| `/repo/output/prm-deductions-base-infra/root-zone-id` |
