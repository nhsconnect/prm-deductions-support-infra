# PRM Deductions support infrastructure

This is the minimal, very first setup of terraform backend in S3 and DynamoDB.

The terraform state produced in this repository is pushed to a separate bucked with AWS CLI.

# Utility scripts

Folder `utils` contains common scripts to be used across projects.

## Generating certificates

Export your AWS credentials in shell (if you have credentials in `~/.aws/credentials` that will work too):
```
export AWS_ACCESS_KEY_ID=***********
export AWS_SECRET_ACCESS_KEY=**************************
unset AWS_SESSION_TOKEN
```

Enter docker container with openssl and AWS CLI by typing:
```
dojo
```
at the root of this repository.

Assume role with elevated permissions:
```
eval $(aws-cli-assumerole -rmfa <role-arn> <your-username> <mfa-otp-code>)
```

To issue certificates for `example.dev.patient-deductions.nhs.uk` run
```
./utils/generate-certs.sh -f example.dev -d example.dev.patient-deductions.nhs.uk
```

The files matching pattern of `example.dev*` will be generated in `./utils/site-certs/*`. 
