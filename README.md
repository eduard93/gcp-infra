This repository is intended to demonstrate ISC Mirroring Failover in GCP cloud.

- [Tools](#tools)
- [IaC](#iac)
  - [Define required variables](#define-required-variables)
  - [Prepare Artifact Registry](#prepare-artifact-registry)
  - [Prepare Docker images](#prepare-docker-images)
  - [Put IRIS license](#put-iris-license)
  - [Create Terraform Role](#create-terraform-role)
  - [Create Service Account with Terraform role](#create-service-account-with-terraform-role)
  - [Generate Service Account key](#generate-service-account-key)
  - [Generate SSH keypair](#generate-ssh-keypair)
  - [Create Cloud Storage](#create-cloud-storage)
  - [Create resources with Terraform](#create-resources-with-terraform)
- [Quick test](#quick-test)
  - [Access to IRIS mirror instances with SSH](#access-to-iris-mirror-instances-with-ssh)
  - [Access to IRIS mirror instances Management Portals](#access-to-iris-mirror-instances-management-portals)
  - [Test](#test)
- [Cleanup](#cleanup)
  - [Remove infrastructure](#remove-infrastructure)
  - [Remove Artifact Registry](#remove-artifact-registry)
  - [Remove Cloud Storage](#remove-cloud-storage)
  - [Remove Terraform Role](#remove-terraform-role)


## Tools
[gcloud](https://cloud.google.com/sdk/docs/install):
```bash
$ gcloud version
Google Cloud SDK 459.0.0
...
```

[terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli):
```bash
$ terraform version
Terraform v1.6.3
```

[python](https://www.python.org/downloads/):
```bash
$ python3 --version
Python 3.10.12
```

[ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html):
```bash
$ ansible --version
ansible [core 2.12.5]
...
```

[ansible-playbook](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html):
```bash
$ ansible-playbook --version
ansible-playbook [core 2.12.5]
...
```

## IaC
We leverage Terraform and store its state in a Cloud Storage. See detail below about how this storage is created.

### Define required variables
```bash
$ export PROJECT_ID=<project_id>
$ export REGION=<region> # For instance, us-west1
$ export TF_VAR_project_id=${PROJECT_ID}
$ export TF_VAR_region=${REGION}
$ export ROLE_NAME=MyTerraformRole
$ export SA_NAME=isc-mirror
```
**Note**: If you'd like to expose IRIS Mirror ports publicly (it's **not recommended**) you could enable it with:
```bash
$ export TF_VAR_enable_mirror_public_ip=true

```

### Prepare Artifact Registry
It's [recommended](https://cloud.google.com/container-registry/docs/advanced-authentication) to leverage Google Artifact Registry instead of Container Registry. So let's create registry first:
```bash
$ cd <root_repo_dir>/terraform
$ cat ${SA_NAME}.json | docker login -u _json_key --password-stdin https://${REGION}-docker.pkg.dev
$ gcloud artifacts repositories create --repository-format=docker --location=${REGION} intersystems
```

### Prepare Docker images
Let's assume that VM instances don't have an access to ISC container repository. But you personally do have and at the same do not want to put your personal credentials on VMs.

In that case you can pull IRIS Docker images from ISC container registry and push them to Google container registry where VMs have an access to:
```bash
$ docker login containers.intersystems.com
$ <Put your credentials here>

$ export IRIS_VERSION=2023.2.0.221.0

$ cd docker-compose/iris
$ docker build -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/intersystems/iris:${IRIS_VERSION} .

$ for IMAGE in webgateway arbiter; do \
    docker pull containers.intersystems.com/intersystems/${IMAGE}:${IRIS_VERSION} \
    && docker tag containers.intersystems.com/intersystems/${IMAGE}:${IRIS_VERSION} ${REGION}-docker.pkg.dev/${PROJECT_ID}/intersystems/${IMAGE}:${IRIS_VERSION} \
    && docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/intersystems/${IMAGE}:${IRIS_VERSION}; \
done

$ docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/intersystems/iris:${IRIS_VERSION}
```

### Put IRIS license
Put IRIS license key file, `iris.key` to `<root_repo_dir>/docker-compose/iris/iris.key`. Note that a license has to support Mirroring.

### Create Terraform Role
This role will be used by Terraform for managing needed GCP resources:

```bash
$ cd <root_repo_dir>/terraform/
$ gcloud iam roles create ${ROLE_NAME} --project ${PROJECT_ID} --file=terraform-permissions.yaml
```
**Note**: use `update` for later usage:
```bash
$ gcloud iam roles update ${ROLE_NAME} --project ${PROJECT_ID} --file=terraform-permissions.yaml
```

### Create Service Account with Terraform role
```bash
$ gcloud iam service-accounts create ${SA_NAME} \
    --description="Terraform Service Account for ISC Mirroring" \
    --display-name="Terraform Service Account for ISC Mirroring"

$ gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role=projects/${PROJECT_ID}/roles/${ROLE_NAME}
```

### Generate Service Account key
Generate Service Account key and store its value in a certain environment variable:
```bash
$ gcloud iam service-accounts keys create ${SA_NAME}.json \
    --iam-account=${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com

$ export GOOGLE_APPLICATION_CREDENTIALS=<absolute_path_to_root_repo_dir>/terraform/${SA_NAME}.json
```

### Generate SSH keypair
Store a private part locally as `.ssh/isc_mirror` and make it visible for `ssh-agent`. Put a public part to a file [isc_mirror.pub](../terraform/templates/isc_mirror.pub):
```bash
$ ssh-keygen -b 4096 -C "isc" -f ~/.ssh/isc_mirror
$ ssh-add  ~/.ssh/isc_mirror
$ ssh-add -l # Check if 'isc' key is present
$ cp ~/.ssh/isc_mirror.pub <root_repo_dir>/terraform/templates/
```

### Create Cloud Storage
Cloud Storage is used for storing [Terraform state remotely](https://developer.hashicorp.com/terraform/language/state/remote). You could take a look at [Store Terraform state in a Cloud Storage bucket](https://cloud.google.com/docs/terraform/resource-management/store-state) as an example.

**Note**: created Cloud Storage will have a name like `isc-mirror-demo-terraform-<project_id>`:
```bash
$ cd <root_repo_dir>/terraform-storage/
$ terraform init
$ terraform plan
$ terraform apply
```

### Create resources with Terraform
```bash
$ cd <root_repo_dir>/terraform/
$ terraform init -backend-config="bucket=isc-mirror-demo-terraform-${PROJECT_ID}"
$ terraform plan
$ terraform apply
```
**Note 1**: Four virtual machines will be created. Only one of them has a public IP address and plays a role of bastion host. This machine is called `isc-client-001`. You can find a public IP of `isc-client-001` instance by running the following command:
```bash
$ export ISC_CLIENT_PUBLIC_IP=$(gcloud compute instances describe isc-client-001 --zone=${REGION}-c --format=json | jq -r '.networkInterfaces[].accessConfigs[].natIP')
```

**Note 2**: Sometimes Terraform fails with errors like:
```bash
Failed to connect to the host via ssh: kex_exchange_identification: Connection closed by remote host...
```
In that case try to clean a local `~/.ssh/known_hosts` file:
```bash
$ for IP in ${ISC_CLIENT_PUBLIC_IP} 10.0.0.{3..6}; do ssh-keygen -R "[${IP}]:2180"; done
```
and then repeat `terraform apply`.


## Quick test
### Access to IRIS mirror instances with SSH
All instances, except `isc-client-001`, are created in a private network to increase a security level. But you can access them using [SSH ProxyJump](https://goteleport.com/blog/ssh-proxyjump-ssh-proxycommand/) feature. Get the `isc-client-001` public IP first:
```bash
$ export ISC_CLIENT_PUBLIC_IP=$(gcloud compute instances describe isc-client-001 --zone=${REGION}-c --format=json | jq -r '.networkInterfaces[].accessConfigs[].natIP')
```
Then connect to, for example, `isc-primary-001` with a private SSH key. Note that we use a custom SSH port, `2180`:
```bash
$ ssh -i ~/.ssh/isc_mirror -p 2180 isc@10.0.0.3 -o ProxyJump=isc@${ISC_CLIENT_PUBLIC_IP}:2180
```
After connection, let's check that Primary mirror member has Alias IP:
```bash
[isc@isc-primary-001 ~]$ ip route ls table local type local dev eth0 scope host proto 66
local 10.0.0.250

[isc@isc-primary-001 ~]$ ping -c 1 10.0.0.250
PING 10.0.0.250 (10.0.0.250) 56(84) bytes of data.
64 bytes from 10.0.0.250: icmp_seq=1 ttl=64 time=0.049 ms
```

### Access to IRIS mirror instances Management Portals
To open mirror instances Management Portals located in a private network, we leverage [SSH Socks Tunneling](https://goteleport.com/blog/ssh-tunneling-explained/).

Let's connect to `isc-primary-001` instance. Note that a tunnel will live in a background after the next command:
```bash
$ ssh -f -N  -i ~/.ssh/isc_mirror -p 2180 isc@10.0.0.3 -o ProxyJump=isc@${ISC_CLIENT_PUBLIC_IP}:2180 -L 8080:10.0.0.3:8080
```
Port 8080, instead of a familiar 52773, is used because we start IRIS with a dedicated WebGateway running on port 8080.

After successful connection, open [http://127.0.0.1:8080/csp/sys/UtilHome.csp](http://127.0.0.1:8080/csp/sys/UtilHome.csp) in a browser. You should see a Management Portal. Credentials are typical: `_system/SYS`.

The same approach works for all instances: primary (10.0.0.3), backup (10.0.0.4) and arbiter (10.0.0.5). Just make an SSH connection to them first.

### Test
Let's connect to `isc-client-001`:
```bash
$ ssh -i ~/.ssh/isc_mirror -p 2180 isc@${ISC_CLIENT_PUBLIC_IP}
```

Check Primary mirror member's Management Portal availability on Alias IP address:
```bash
$ curl -s -o /dev/null -w "%{http_code}\n" http://10.0.0.250:8080/csp/sys/UtilHome.csp
200
```
Let's connect to `isc-primary-001` on another console:
```bash
$ ssh -i ~/.ssh/isc_mirror -p 2180 isc@10.0.0.3 -o ProxyJump=isc@${ISC_CLIENT_PUBLIC_IP}:2180
```
And switch the current Primary instance off. Note that IRIS as well as its WebGateway is running in Docker:
```bash
[isc@isc-primary-001 ~]$ docker-compose -f /isc-mirror/docker-compose.yml down
```
Let's check mirror member's Management Portal availability on Alias IP address again from `isc-client-001`:
```bash
[isc@isc-client-001 ~]$ curl -s -o /dev/null -w "%{http_code}\n" http://10.0.0.250:8080/csp/sys/UtilHome.csp
200
```
It should work as Alias IP was moved to `isc-backup-001` instance:
```bash
$ ssh -i ~/.ssh/isc_mirror -p 2180 isc@10.0.0.4 -o ProxyJump=isc@${ISC_CLIENT_PUBLIC_IP}:2180
[isc@isc-backup-001 ~]$ ip route ls table local type local dev eth0 scope host proto 66
local 10.0.0.250
```
**TODO** - describe how to return the former primary instance back after failover.

## Cleanup

### Remove infrastructure
```bash
$ cd <root_repo_dir>/terraform/
$ terraform init -backend-config="bucket=isc-mirror-demo-terraform-${PROJECT_ID}"
$ terraform destroy
```

### Remove Artifact Registry
```bash
$ cd <root_repo_dir>/terraform
$ cat ${SA_NAME}.json | docker login -u _json_key --password-stdin https://${REGION}-docker.pkg.dev

$ for IMAGE in iris webgateway arbiter; do \
    gcloud artifacts docker images delete ${REGION}-docker.pkg.dev/${PROJECT_ID}/intersystems/${IMAGE}
done
$ gcloud artifacts repositories delete intersystems --location=${REGION}
```

### Remove Cloud Storage
Remove Cloud Storage where Terraform stores its state. In our case, it's a `isc-mirror-demo-terraform-<project_id>`.


### Remove Terraform Role
Remove Terraform Role created in [Create Terraform Role](#create-terraform-role).
