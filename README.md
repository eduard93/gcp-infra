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
$ export PROJECT_ID=<project_id>
$ export REGION=<region> # For instance, us-west1
$ export TF_VAR_project_id=${PROJECT_ID}
$ export ROLE_NAME=MyTerraformRole
$ export SA_NAME=isc-mirror
```

2. Create Role used by Terraform for managing needed GCP resources:

```
$ cd terraform

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

7. Create resources with Terraform:
```
$ terraform init
$ terraform plan
$ terraform apply
```
**Note 1**: You can find a public IP of `isc-client-001` instance by running the following command:
```
$ export ISC_CLIENT_PUBLIC_IP=$(gcloud compute instances describe isc-client-001 --zone=us-west1-c --format=json | jq -r '.networkInterfaces[].accessConfigs[].natIP')
```

**Note 2**: Sometimes Terraform fails with errors like:
```
Failed to connect to the host via ssh: kex_exchange_identification: Connection closed by remote host...
```
In that case try to clean a local `~/.ssh/known_hosts` file:
```
$ for IP in ${ISC_CLIENT_PUBLIC_IP} 10.0.0.{3..6}; do ssh-keygen -R ${IP}; done
```
and then repeat `terraform apply`.

# Prepare Artifact Registry
It's [recommended](https://cloud.google.com/container-registry/docs/advanced-authentication) to leverage Google Artifact Registry instead of Container Registry. So let's create registry first:
```
$ cd <root_repo_dir>/terraform
$ cat ${SA_NAME}.json | base64 | tr -d '\n' | docker login -u _json_key_base64 --password-stdin https://${REGION}-docker.pkg.dev
$ gcloud artifacts repositories create --repository-format=docker --location=${REGION} intersystems
```

## Prepare Docker images
Let's assume that VM instances don't have an access to ISC container repository. But you personally do have and at the same do not want to put your personal credentials on VMs.

In that case you can pull IRIS Docker images from ISC container registry and push them to Google container registry where VMs have an access to:
```
$ docker login containers.intersystems.com
$ <Put your credentials here>

$ export IRIS_VERSION=2023.2.0.221.0

$ cd docker-compose/iris
$ docker build -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/intersystems/iris:${IRIS_VERSION} .

$ for IMAGE in iris webgateway arbiter; do \
    docker pull containers.intersystems.com/intersystems/${IMAGE}:${IRIS_VERSION} \
    && docker tag containers.intersystems.com/intersystems/${IMAGE}:${IRIS_VERSION} ${REGION}-docker.pkg.dev/${PROJECT_ID}/intersystems/${IMAGE}:${IRIS_VERSION} \
    && docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/intersystems/${IMAGE}:${IRIS_VERSION}; \
done

$ docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/intersystems/iris:${IRIS_VERSION}
```

## Put IRIS license
Put IRIS license key file, `iris.key` to <root_repo_dir>/docker-compose/iris/iris.key. Note that a license has to support Mirroring.


## Provisioning
Terraform runs Ansible right after infrastructure creation. So you're not required to do it manually.
