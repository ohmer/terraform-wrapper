# tfwrapper

tfwrapper is a python wrapper for [Terraform](https://www.terraform.io/) which aims to simplify Terraform usage and enforce best practices.

## Features

- Terraform behaviour overriding
- State centralization enforcement
- Standardized file structure
- AWS credentials caching
- Plugins caching

## Drawbacks

- AWS only (even if other providers may work)
- Setup overhead

## Dependencies

- Make
- Python `>= 3.5`
- python-pip
- python-virtualenv
- Terraform `>= 0.11`
- An AWS S3 bucket and DynamoDB table for state centralization.

## Installation

tfwrapper should be deployed as a git submodule in Terraform projects.

```bash
cd my_terraform_project
git submodule add git@github.com:ohmer/terraform-wrapper.git .wrapper
```

If you plan to use tfwrapper for multiple projects, creating a new git repository including all the required files and tfwrapper as a git submodule is recommended. You then just need to clone this repository to start new projects.

### Required files

tfwrapper expects multiple files and directories at the root of its parent project.

#### Makefile

A `Makefile` symlink should point to tfwrapper's `Makefile`. this link allows users to setup and enable tfwrapper from the root of their project.

```bash
ln -s .wrapper/Makefile
```

#### .wrapper.d

Configurations are stored in the `.wrapper.d` directory.

State configuration file must be named `state.yml` and contain following definitions :

```bash
---
profile: '<AWS_SDK_PROFILE_NAME>'           # should be configured in ~/.aws/config
region: '<AWS_REGION>'                      # AWS region where the S3 bucket and DynamoDB table are located
bucket: '<AWS_S3_BUCKET_NAME>'              # S3 bucket name
dynamodb_table: '<AWS_DYNAMODB_TABLE_NAME>' # DynamoDB table name
```

Stacks configuration files use the following naming convention :

```bash
.wrapper.d/${application}_${environment}_${region}_${stack}.yml
```

Here is an example for an AWS stack configuration:

```yaml
---
profile: 'my-aws-profile'     # should be configured in ~/.aws/config
partition: 'my-client-name'   # arbitrary partition name (like a customer name)

terraform:
  vars:                       # variables passed to terraform
    key: 'value'
```

#### .gitignore

Adding the following `.gitignore` at the root of your project is recommended :

```bash
cat << 'EOF' > .gitignore
*/**/terraform.tfstate
*/**/terraform.tfstate.backup
*/**/terraform.tfvars
*/**/.terraform/modules
*/**/.terraform/plugins
EOF
```

## Stacks file structure

Terraform stacks are organized based on their :

- application : an account alias which may reference one or multiple providers accounts. `proxy`, `datalake`, etc…
- environment : `production`, `preproduction`, `dev`, etc…
- region : `eu-west-1`, `us-east-1`, `global`, etc…
- stack : defaults to `default`. `web`, `admin`, `tools`, etc…

The following file structure is enforced :

```
# enforced file structure
└── application
    └── environment
        └── region
            └── stack

# real-life example
├── security
│   └── production
│       ├── eu-central-1
│       │   └── proxy
│       │       └── main.tf
│       └── eu-west-1
│           ├── default
│           │   └── main.tf
│           └── tools
│               └── main.tf
└── aws-app-2
    └── backup
        └── eu-west-1
            └── backup
                └── main.tf
```

## Usage

### tfwrapper activation

```bash
# this will initialize a virtualenv and update your PATH in a new instance of your current SHELL
make
tfwrapper -h

# when you are done using the tfwrapper you can leave the virtualenv
exit
```

### Stack bootstrap

After creating a `.wrapper.d/${application}_${environment}_${region}_${stack}.yml` stack configuration file you can initialize your stack.

```bash
tfwrapper -a ${application} -e ${environment} -r ${region} -s ${stack} init
```

### Working on a stack

You can work on stacks from theirs root or from the root of the project.

```bash
# working from the root of the project
tfwrapper -a ${application} -e ${environment} -r ${region} -s ${stack} plan

# working from the root of a stack
cd ${application}/${environment}/${region}/${stack}
tfwrapper plan
```

### Passing options

You can pass anything you want to `terraform` using `--`.

```bash
tfwrapper plan -- -target resource1 -target resource2
```

## Environment

tfwrapper sets the following environment variables.

### S3 state backend credentials

The default AWS credentials of the environment are set to point to the S3 state backend. Those credentials are acquired from the profile defined in `.wrapper.d/state.yml`

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`

### Stack configurations and credentials

The `terraform_vars` dictionary from the stack configuration is accessible as Terraform variables.

The profile defined in the stack configuration is used to acquire credentials accessible from Terraform.

- `TF_VAR_partition`
- `TF_VAR_aws_access_key`
- `TF_VAR_aws_secret_key`
- `TF_VAR_aws_token`
- `TF_VAR_aws_account`

### Stack path

The stack path is passed to Terraform. This is especially useful for resource naming and tagging.

- `TF_VAR_application`
- `TF_VAR_environment`
- `TF_VAR_aws_region`
- `TF_VAR_stack`
