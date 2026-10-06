#!/usr/bin/env python3
"""Wydanie zaakceptowanej wersji (PENDING_DEVELOPER_RELEASE) w App Store, odpowiednik "Release This Version".
Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8_BASE64, opcjonalnie ASC_VERSION."""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
import prepare  # api(), APP_ID

VERSION = os.environ.get("ASC_VERSION", "1.3.0")
vers = prepare.api(f"/v1/apps/{prepare.APP_ID}/appStoreVersions?filter[platform]=IOS&filter[versionString]={VERSION}")["data"]
if not vers or vers[0]["attributes"]["appStoreState"] != "PENDING_DEVELOPER_RELEASE":
    print("Nie do wydania:", [(v["attributes"]["versionString"], v["attributes"]["appStoreState"]) for v in vers])
    raise SystemExit(1)
prepare.api("/v1/appStoreVersionReleaseRequests", "POST", {"data": {"type": "appStoreVersionReleaseRequests",
            "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": vers[0]["id"]}}}}})
v = prepare.api(f"/v1/appStoreVersions/{vers[0]['id']}")["data"]["attributes"]
print("WYDANE:", VERSION, "stan:", v["appStoreState"])
