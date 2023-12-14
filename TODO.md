- change instance permissions
- change default ssh port (templates/vm_init.sh)
- disable ssh with root user
- do we still need a startup script?
- check that all commented code is removed
- use a specific iris image and license
- review infra.md file (at least, remove hardcoded IPs)
- in Ansible playbook use variables for apps versions
- remove commented lines from terraform-permissions.yaml file
- remove ansible.tf.old file

- The next error during 1-st creation:
null_resource.client (local-exec): fatal: [34.82.229.130]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh: ssh: connect to host 34.82.229.130 port 22: Connection refused", "unreachable": true}

- terraform. Remote state
- run everything with gitlab pipeline
- setup correct node permissions
- do we need a file requirements.txt
- Use iris image with separate web gateway
- Implement https://stackoverflow.com/questions/54923580/how-to-execute-the-gcloud-api-to-move-the-alias-ip-from-one-instance-to-another
