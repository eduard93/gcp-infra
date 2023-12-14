This repository is intended to demonstrate ISC Mirroring Failover in GCP cloud.

- [Tools](#tools)
- [Iac](#iac)
- [Prepare Docker images](#prepare-docker-images)
- [Put IRIS license](#put-iris-license)
- [Provisioning](#provisioning)

## Tools
[gcloud](https://cloud.google.com/sdk/docs/install):
```
$ gcloud version
Google Cloud SDK 455.0.0
...
```

[terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli):
```
$ terraform version
Terraform v1.6.3
```

[python](https://www.python.org/downloads/):
```
$ python3 --version
Python 3.10.12
```

[ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html):
```
$ ansible --version
ansible [core 2.12.5]
...
```

[ansible-playbook](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html):
```
$ ansible-playbook --version
ansible-playbook [core 2.12.5]
...
```

## IaC
1. Define several variables used below, like project ID and so on:
```
$ export PROJECT_ID=zpm-package-manager
$ export TF_VAR_project_id=${PROJECT_ID}
$ export ROLE_NAME=MyTerraformRole
$ export SA_NAME=isc-mirror
```

2. Create Role used by Terraform for managing needed GCP resources:

```
$ gcloud iam roles create ${ROLE_NAME} --project ${PROJECT_ID} --file=terraform-permissions.yaml
```
Note: use `update` for later usage:
```
$ gcloud iam roles update ${ROLE_NAME} --project ${PROJECT_ID} --file=terraform-permissions.yaml
```

3. Create Service Account with Terraform role:
```
$ gcloud iam service-accounts create ${SA_NAME} \
    --description="Terraform Service Account for ISC Mirroring" \
    --display-name="Terraform Service Account for ISC Mirroring"

$ gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role=projects/${PROJECT_ID}/roles/${ROLE_NAME}
```

4. Generate Service Account key and store its value in a certain environment variable:
```
$ gcloud iam service-accounts keys create ${SA_NAME}.json \
    --iam-account=${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com

$ export GOOGLE_APPLICATION_CREDENTIALS=${SA_NAME}.json
```

5. Generate SSH keypair.

Generate SSH keypair. Store a private part locally as `.ssh/isc_mirror`. Put a public part to a file [isc_mirror.pub](../terraform/templates/isc_mirror.pub):
```
$ ssh-keygen -b 4096 -C "isc"
$ cp ~/.ssh/isc_mirror.pub <root_repo_dir>/terraform/templates/
```

6. Create resources with Terraform:
```
$ terraform init
$ terraform plan
$ terraform apply
```

## Prepare Docker images
Let's assume that VM instances don't have an access to ISC container repository. But you personally do have. You can pull IRIS Docker image from ISC container registry, archive it, copy it to VM and unpack that image there.

This is a way to run IRIS containers taken from ISC private repository.

```
$ docker login containers.intersystems.com
$ docker pull containers.intersystems.com/intersystems/iris:2023.1.1.380.0
$ docker save -o <root_repo_dir>/ansible/iris_2023.tar containers.intersystems.com/intersystems/iris:2023.1.1.380.0
```

## Put IRIS license
Put IRIS license key file, `iris.key` to <root_repo_dir>/ansible/iris.key. Note that a license has to support Mirroring.


## Provisioning
```
$ cd ansible/
$ ansible-playbook -i "35.197.41.3," -e ansible_user=isc playbook.yml
```


## TODO
Get zone:
```
$ curl "http://metadata.google.internal/computeMetadata/v1/instance/zone" -H "Metadata-Flavor: Google"
projects/405309937753/zones/us-west1-a
```
Remove alias:
```
$ gcloud compute instances network-interfaces update isc-primary-001 --zone=us-west1-a --aliases=""
```
Add alias:
```
$ gcloud compute instances network-interfaces update isc-primary-001 --zone=us-west1-a --aliases="10.0.0.250/32"
```

Also note [Unusable addresses in IPv4 subnet ranges](https://cloud.google.com/vpc/docs/subnets#unusable-ip-addresses-in-every-subnet).

Google Cloud uses the first two and last two IPv4 addresses in each subnet primary IPv4 address range to host the subnet. Google Cloud lets you use all addresses in secondary IPv4 ranges.

i.e.
- 10.0.0.0 - Network address
- 10.0.0.1 - Default gateway address
- 10.0.0.254 - Second-to-last address. Reserved for potential future use
- 10.0.0.255 - Broadcast address
