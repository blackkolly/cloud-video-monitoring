"""
Cloudflare Metrics Exporter Script

Fetches analytics data from Cloudflare API and prints key metrics for integration with monitoring systems (e.g., Prometheus Pushgateway, custom ingestion, etc).

Requirements:
- requests

Usage:
  Set the following environment variables before running:
    CLOUDFLARE_API_TOKEN=<your_api_token>
    CLOUDFLARE_ZONE_ID=<your_zone_id>

  python cloudflare_metrics_exporter.py
"""
import os
import requests
import sys

CLOUDFLARE_API_TOKEN = os.getenv('CLOUDFLARE_API_TOKEN')
CLOUDFLARE_ZONE_ID = os.getenv('CLOUDFLARE_ZONE_ID')

if not CLOUDFLARE_API_TOKEN or not CLOUDFLARE_ZONE_ID:
    print("Error: CLOUDFLARE_API_TOKEN and CLOUDFLARE_ZONE_ID must be set as environment variables.")
    sys.exit(1)

API_URL = f"https://api.cloudflare.com/client/v4/zones/{CLOUDFLARE_ZONE_ID}/analytics/dashboard"
HEADERS = {
    "Authorization": f"Bearer {CLOUDFLARE_API_TOKEN}",
    "Content-Type": "application/json"
}

def fetch_cloudflare_analytics():
    response = requests.get(API_URL, headers=HEADERS)
    if response.status_code != 200:
        print(f"Failed to fetch analytics: {response.status_code} {response.text}")
        sys.exit(1)
    return response.json()

def print_metrics(data):
    totals = data.get('result', {}).get('totals', {})
    if not totals:
        print("No totals found in Cloudflare analytics response.")
        return
    print("Cloudflare Analytics Metrics:")
    print(f"Requests: {totals.get('requests', 0)}")
    print(f"Bandwidth (bytes): {totals.get('bandwidth', 0)}")
    print(f"Threats: {totals.get('threats', 0)}")
    print(f"Pageviews: {totals.get('pageviews', 0)}")
    print(f"Unique Visitors: {totals.get('uniques', 0)}")
    print(f"Cached Requests: {totals.get('cachedRequests', 0)}")
    print(f"Cached Bandwidth: {totals.get('cachedBandwidth', 0)}")
    print(f"SSL Requests: {totals.get('ssl', 0)}")
    print(f"HTTP Status 2xx: {totals.get('httpStatus', {}).get('2xx', 0)}")
    print(f"HTTP Status 4xx: {totals.get('httpStatus', {}).get('4xx', 0)}")
    print(f"HTTP Status 5xx: {totals.get('httpStatus', {}).get('5xx', 0)}")

def main():
    data = fetch_cloudflare_analytics()
    print_metrics(data)

if __name__ == "__main__":
    main()
