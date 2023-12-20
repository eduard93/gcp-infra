import requests
from google.cloud import compute_v1

ALIAS_IP = "10.0.0.250/32"
METADATA_URL = "http://metadata.google.internal/computeMetadata/v1/"
METADATA_HEADERS = {"Metadata-Flavor": "Google"}
project_path = "project/project-id"
instance_path = "instance/name"
zone_path = "instance/zone"
network_interface = "nic0"


def get_metadata(path: str) -> str:
    return requests.get(METADATA_URL + path, headers=METADATA_HEADERS).text


def update_network_interface() -> None:
    project = get_metadata(project_path)
    zone = get_metadata(zone_path).split('/')[3]
    instance = get_metadata(instance_path)

    # Create an instance client
    client = compute_v1.InstancesClient()

    # Initialize IP range
    alias_ip_range = compute_v1.AliasIpRange(
        ip_cidr_range=ALIAS_IP,
    )

    # Initialize Network Interface
    nic = compute_v1.NetworkInterface(
        alias_ip_ranges=[alias_ip_range],
        fingerprint=client.get(
            instance=instance,
            project=project,
            zone=zone
        ).network_interfaces[0].fingerprint,
    )

    # Initialize request
    request = compute_v1.UpdateNetworkInterfaceInstanceRequest(
        project=project,
        zone=zone,
        instance=instance,
        network_interface_resource=nic,
        network_interface=network_interface,
    )

    # Make the request
    response = client.update_network_interface(request=request)

    # Handle the response
    print(response.status)


update_network_interface()
