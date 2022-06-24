{
  "schemaVersion": "1.0.0",
  "class": "Device",
  "async": true,
  "label": "my BIG-IP declaration for declarative onboarding",
  "Common": {
    "class": "Tenant",
    "hostname": "${hostname}",
    "${admin_user}": {
      "class": "User",
      "userType": "regular",
      "password": "${admin_password}",
      "shell": "bash"
    },
    "myProvisioning": {
      "class": "Provision",
      "ltm": "nominal",
      "gtm": "minimum"
    },
    "external": {
      "class": "VLAN",
      "tag": 4093,
      "mtu": 1500,
      "interfaces": [
        {
          "name": "1.1",
          "tagged": false
        }
      ],
      "cmpHash": "dst-ip"
    },
    "external-self": {
      "class": "SelfIp",
      "address": "${external_self_ip}",
      "vlan": "external",
      "allowService": "default",
      "trafficGroup": "traffic-group-local-only"
    },
    "internal": {
      "class": "VLAN",
      "tag": 4092,
      "mtu": 1500,
      "interfaces": [
        {
          "name": "1.2",
          "tagged": false
        }
      ],
      "cmpHash": "dst-ip"
    },
    "internal-self": {
      "class": "SelfIp",
      "address": "${internal_self_ip}",
      "vlan": "internal",
      "allowService": "default",
      "trafficGroup": "traffic-group-local-only"
    }
  }
}