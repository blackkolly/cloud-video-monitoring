"""
Cloudflare Prometheus Exporter

Fetches Cloudflare analytics and exposes them on a /metrics HTTP endpoint for Prometheus scraping.

Requirements:
- requests
- prometheus_client

Usage:
  Set environment variables:
    CLOUDFLARE_API_TOKEN=<your_api_token>
    CLOUDFLARE_ZONE_ID=<your_zone_id>
  Run:
    python cloudflare_prometheus_exporter.py
  Then configure Prometheus to scrape http://<host>:8000/metrics
"""
import os
import sys
import requests
from prometheus_client import start_http_server, Gauge, CollectorRegistry, generate_latest
from prometheus_client.core import REGISTRY
from flask import Flask, Response

CLOUDFLARE_API_TOKEN = os.getenv('CLOUDFLARE_API_TOKEN')
CLOUDFLARE_ZONE_ID = os.getenv('CLOUDFLARE_ZONE_ID')
PORT = int(os.getenv('EXPORTER_PORT', 8000))

if not CLOUDFLARE_API_TOKEN or not CLOUDFLARE_ZONE_ID:
    print("Error: CLOUDFLARE_API_TOKEN and CLOUDFLARE_ZONE_ID must be set as environment variables.")
    sys.exit(1)

API_URL = f"https://api.cloudflare.com/client/v4/zones/{CLOUDFLARE_ZONE_ID}/analytics/dashboard"
HEADERS = {
    "Authorization": f"Bearer {CLOUDFLARE_API_TOKEN}",
    "Content-Type": "application/json"
}

app = Flask(__name__)

# Define Prometheus Gauges
cf_requests = Gauge('cloudflare_requests', 'Total requests', [])
cf_bandwidth = Gauge('cloudflare_bandwidth_bytes', 'Total bandwidth in bytes', [])
cf_threats = Gauge('cloudflare_threats', 'Total threats', [])
cf_pageviews = Gauge('cloudflare_pageviews', 'Total pageviews', [])
cf_uniques = Gauge('cloudflare_uniques', 'Unique visitors', [])
cf_cached_requests = Gauge('cloudflare_cached_requests', 'Cached requests', [])
cf_cached_bandwidth = Gauge('cloudflare_cached_bandwidth_bytes', 'Cached bandwidth in bytes', [])
cf_ssl_requests = Gauge('cloudflare_ssl_requests', 'SSL requests', [])
cf_http_2xx = Gauge('cloudflare_http_2xx', 'HTTP 2xx responses', [])
cf_http_4xx = Gauge('cloudflare_http_4xx', 'HTTP 4xx responses', [])
cf_http_5xx = Gauge('cloudflare_http_5xx', 'HTTP 5xx responses', [])

def fetch_cloudflare_analytics():
    response = requests.get(API_URL, headers=HEADERS)
    if response.status_code != 200:
        print(f"Failed to fetch analytics: {response.status_code} {response.text}")
        return None
    return response.json()

def update_metrics():
    data = fetch_cloudflare_analytics()
    if not data:
        return
    totals = data.get('result', {}).get('totals', {})
    cf_requests.set(totals.get('requests', 0))
    cf_bandwidth.set(totals.get('bandwidth', 0))
    cf_threats.set(totals.get('threats', 0))
    cf_pageviews.set(totals.get('pageviews', 0))
    cf_uniques.set(totals.get('uniques', 0))
    cf_cached_requests.set(totals.get('cachedRequests', 0))
    cf_cached_bandwidth.set(totals.get('cachedBandwidth', 0))
    cf_ssl_requests.set(totals.get('ssl', 0))
    cf_http_2xx.set(totals.get('httpStatus', {}).get('2xx', 0))
    cf_http_4xx.set(totals.get('httpStatus', {}).get('4xx', 0))
    cf_http_5xx.set(totals.get('httpStatus', {}).get('5xx', 0))

@app.route('/metrics')
def metrics():
    update_metrics()
    return Response(generate_latest(REGISTRY), mimetype='text/plain')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=PORT)
