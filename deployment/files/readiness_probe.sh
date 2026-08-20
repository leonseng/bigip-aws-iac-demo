#!/usr/bin/env bash
until curl -sku $BIGIP_USERNAME:$BIGIP_PASSWORD $BIGIP_MGMT_URL/mgmt/shared/appsvcs/info | grep version > /dev/null;
do
  sleep 1;
done
