#!/usr/bin/env bash
until curl -sku $BIGIP_USERNAME:$BIGIP_PASSWORD $BIGIP_MGMT_URL/mgmt/toc | grep f5RestTOCApp > /dev/null;
do
  sleep 1;
done
