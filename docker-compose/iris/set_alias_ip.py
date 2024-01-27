"""
This script adds Alias IP (https://cloud.google.com/vpc/docs/alias-ip) to the VM Network Interface.

You can allocate alias IP ranges from the primary subnet range, or you can add a secondary range to the subnet
and allocate alias IP ranges from the secondary range.
For simplicity, we use the primary subnet range.

Using google cli, gcloud, this action could be performed in this way:
$ gcloud compute instances network-interfaces update <instance_name> --zone=<subnet_zone> --aliases="10.0.0.250/32"

Note that the command for alias removal looks similar - just provide an empty `aliases`:
$ gcloud compute instances network-interfaces update <instance_name> --zone=<subnet_zone> --aliases=""

We leverage Google Compute Engine Metadata API to retrieve <instance_name> as well as <subnet_zone>.

Also note https://cloud.google.com/vpc/docs/subnets#unusable-ip-addresses-in-every-subnet.

Google Cloud uses the first two and last two IPv4 addresses in each subnet primary IPv4 address range to host the subnet.
Google Cloud lets you use all addresses in secondary IPv4 ranges, i.e.:
- 10.0.0.0 - Network address
- 10.0.0.1 - Default gateway address
- 10.0.0.254 - Second-to-last address. Reserved for potential future use
- 10.0.0.255 - Broadcast address

After adding Alias IP, you can check its existence using 'ip' utility:
$ ip route ls table local type local dev eth0 scope host proto 66
local 10.0.0.250
"""

import subprocess
import requests
import re
from google.cloud import compute_v1

ALIAS_IP = "10.0.0.250/32"
METADATA_URL = "http://metadata.google.internal/computeMetadata/v1/"
METADATA_HEADERS = {"Metadata-Flavor": "Google"}
project_path = "project/project-id"
instance_path = "instance/name"
zone_path = "instance/zone"
network_interface = "nic0"
mirror_instances = ["isc-primary-001", "isc-backup-001"]

client = compute_v1.InstancesClient()


def get_metadata(path: str) -> str:
    return requests.get(METADATA_URL + path, headers=METADATA_HEADERS).text


def get_region() -> str:
    return get_metadata(zone_path).split('/')[3]


def get_zone_by_instance_name_and_region(instance_name: str, region: str) -> str:
    project = get_metadata(project_path)

    request = compute_v1.AggregatedListInstancesRequest()
    request.project = project

    instance_zone = ""
    for zone, response in client.aggregated_list(request=request):
        if response.instances:
            if re.search(f"{region}*", zone):
                for instance in response.instances:
                    if instance.name == instance_name:
                        return zone.split('/')[1]
    return instance_zone


def update_network_interface(action: str, instance_name: str, zone: str) -> None:
    project = get_metadata(project_path)

    # Initialize IP range
    if action == "create":
        alias_ip_range = compute_v1.AliasIpRange(
            ip_cidr_range=ALIAS_IP,
        )

    # Initialize Network Interface
    nic = compute_v1.NetworkInterface(
        alias_ip_ranges=[] if action == "delete" else [alias_ip_range],
        fingerprint=client.get(
            instance=instance_name,
            project=project,
            zone=zone
        ).network_interfaces[0].fingerprint,
    )

    # Initialize request
    request = compute_v1.UpdateNetworkInterfaceInstanceRequest(
        project=project,
        zone=zone,
        instance=instance_name,
        network_interface_resource=nic,
        network_interface=network_interface,
    )

    # Make the request
    response = client.update_network_interface(request=request)

    # Handle the response
    print(instance_name + ": " + str(response.status))


def get_remote_instance_name() -> str:
    local_instance = get_metadata(instance_path)
    mirror_instances.remove(local_instance)
    return ''.join(mirror_instances)

# Get another failover member's instance name and zone
remote_instance = get_remote_instance_name()
print("Alias IP is going to be deleted at: " + remote_instance)

# Remove Alias IP from a remote failover member's Network Interface
#
# TODO: Perform the next steps when an issue https://github.com/googleapis/google-cloud-python/issues/11931 will be closed:
# - update google-cloud-compute pip package to a version containing fix (>1.15.0)
# - remove a below line calling gcloud with subprocess.run()
# - uncomment update_network_interface() function
subprocess.run([
    "gcloud",
    "compute",
    "instances",
    "network-interfaces",
    "update",
    remote_instance,
    "--zone=" + get_zone_by_instance_name_and_region(remote_instance,  get_region()),
    "--aliases="
])
# update_network_interface("delete",
#                          remote_instance,
#                          get_zone_by_instance_name_and_region(remote_instance,  get_region())


# Add Alias IP to a local failover member's Network Interface
update_network_interface("create",
                         get_metadata(instance_path),
                         get_region())
