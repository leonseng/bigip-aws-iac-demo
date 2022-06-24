{
  "class": "AS3",
  "action": "deploy",
  "persist": true,
  "declaration": {
    "class": "ADC",
    "schemaVersion": "3.0.0",
    "id": "123abc",
    "label": "AS3 Sample",
    "remark": "HTTPS VS to AWS Fargate containers",
    "AS3_Sample": {
      "class": "Tenant",
      "F5_Demo_Httpd": {
        "class": "Application",
        "service": {
          "class": "Service_HTTPS",
          "virtualAddresses": [
            "${vs_vip}"
          ],
          "pool": "workload_pool",
          "serverTLS": "webtls",
          "persistenceMethods": []
        },
        "workload_pool": {
          "class": "Pool",
          "monitors": [
            "http"
          ],
          "members": [{
            "servicePort": 80,
            "serverAddresses": [
              ${server_addresses}
            ]
          }]
        },
        "webtls": {
          "class": "TLS_Server",
          "certificates": [
            {
              "certificate": "tlsserver_local_cert"
            }
          ]
        },
        "tlsserver_local_cert": {
          "class": "Certificate",
          "certificate": {"bigip":"/Common/default.crt"},
          "privateKey": {"bigip":"/Common/default.key"}
        }
      }
    }
  }
}