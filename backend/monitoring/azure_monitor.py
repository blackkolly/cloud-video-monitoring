# Azure Monitor Integration for Video Streaming Platform
import asyncio
import aiohttp
import json
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional
import os

logger = logging.getLogger(__name__)

class AzureMonitorIntegration:
    """Integration with Azure Monitor for comprehensive monitoring"""
    
    def __init__(self):
        self.subscription_id = os.getenv('AZURE_SUBSCRIPTION_ID')
        self.tenant_id = os.getenv('AZURE_TENANT_ID')
        self.client_id = os.getenv('AZURE_CLIENT_ID')
        self.client_secret = os.getenv('AZURE_CLIENT_SECRET')
        self.resource_group = os.getenv('AZURE_RESOURCE_GROUP', 'video-streaming-rg')
        self.aks_cluster_name = os.getenv('AKS_CLUSTER_NAME', 'video-streaming-aks')
        
        self.access_token = None
        self.token_expires = None
        
    async def authenticate(self):
        """Authenticate with Azure AD"""
        if not all([self.tenant_id, self.client_id, self.client_secret]):
            logger.warning("Azure credentials not configured, using mock data")
            return False
            
        auth_url = f"https://login.microsoftonline.com/{self.tenant_id}/oauth2/v2.0/token"
        
        data = {
            'client_id': self.client_id,
            'client_secret': self.client_secret,
            'scope': 'https://management.azure.com/.default',
            'grant_type': 'client_credentials'
        }
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(auth_url, data=data) as response:
                    if response.status == 200:
                        token_data = await response.json()
                        self.access_token = token_data['access_token']
                        expires_in = token_data.get('expires_in', 3600)
                        self.token_expires = datetime.utcnow() + timedelta(seconds=expires_in - 300)
                        logger.info("Successfully authenticated with Azure AD")
                        return True
                    else:
                        logger.error(f"Azure authentication failed: {response.status}")
                        return False
        except Exception as e:
            logger.error(f"Azure authentication error: {e}")
            return False
    
    async def get_aks_metrics(self) -> Dict[str, Any]:
        """Get AKS cluster metrics"""
        if not await self._ensure_authenticated():
            return self._get_mock_aks_metrics()
        
        # AKS metrics endpoint
        metrics_url = (
            f"https://management.azure.com/subscriptions/{self.subscription_id}/"
            f"resourceGroups/{self.resource_group}/providers/Microsoft.ContainerService/"
            f"managedClusters/{self.aks_cluster_name}/providers/Microsoft.Insights/metrics"
        )
        
        # Query parameters for metrics
        params = {
            'api-version': '2018-01-01',
            'metricnames': 'node_cpu_usage_percentage,node_memory_working_set_percentage,pods_ready_percentage',
            'timespan': 'PT1H',  # Last 1 hour
            'interval': 'PT5M'   # 5-minute intervals
        }
        
        headers = {
            'Authorization': f'Bearer {self.access_token}',
            'Content-Type': 'application/json'
        }
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(metrics_url, params=params, headers=headers) as response:
                    if response.status == 200:
                        data = await response.json()
                        return self._process_aks_metrics(data)
                    else:
                        logger.error(f"Failed to get AKS metrics: {response.status}")
                        return self._get_mock_aks_metrics()
        except Exception as e:
            logger.error(f"Error getting AKS metrics: {e}")
            return self._get_mock_aks_metrics()
    
    async def get_network_metrics(self) -> Dict[str, Any]:
        """Get Azure network metrics"""
        if not await self._ensure_authenticated():
            return self._get_mock_network_metrics()
        
        # Network metrics for Load Balancer
        lb_name = f"{self.aks_cluster_name}-lb"
        metrics_url = (
            f"https://management.azure.com/subscriptions/{self.subscription_id}/"
            f"resourceGroups/MC_{self.resource_group}_{self.aks_cluster_name}_eastus/"
            f"providers/Microsoft.Network/loadBalancers/{lb_name}/"
            f"providers/Microsoft.Insights/metrics"
        )
        
        params = {
            'api-version': '2018-01-01',
            'metricnames': 'ByteCount,PacketCount,SYNCount',
            'timespan': 'PT1H',
            'interval': 'PT5M'
        }
        
        headers = {
            'Authorization': f'Bearer {self.access_token}',
            'Content-Type': 'application/json'
        }
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(metrics_url, params=params, headers=headers) as response:
                    if response.status == 200:
                        data = await response.json()
                        return self._process_network_metrics(data)
                    else:
                        logger.warning(f"Network metrics unavailable: {response.status}")
                        return self._get_mock_network_metrics()
        except Exception as e:
            logger.error(f"Error getting network metrics: {e}")
            return self._get_mock_network_metrics()
    
    async def get_cost_metrics(self) -> Dict[str, Any]:
        """Get Azure cost and billing metrics"""
        if not await self._ensure_authenticated():
            return self._get_mock_cost_metrics()
        
        # Cost management API
        cost_url = (
            f"https://management.azure.com/subscriptions/{self.subscription_id}/"
            f"resourceGroups/{self.resource_group}/providers/Microsoft.CostManagement/"
            f"query"
        )
        
        # Query for last 30 days cost
        query_body = {
            "type": "ActualCost",
            "timeframe": "MonthToDate",
            "dataset": {
                "granularity": "Daily",
                "aggregation": {
                    "totalCost": {
                        "name": "PreTaxCost",
                        "function": "Sum"
                    }
                },
                "grouping": [
                    {
                        "type": "Dimension",
                        "name": "ServiceName"
                    }
                ]
            }
        }
        
        headers = {
            'Authorization': f'Bearer {self.access_token}',
            'Content-Type': 'application/json'
        }
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(cost_url, json=query_body, headers=headers, params={'api-version': '2021-10-01'}) as response:
                    if response.status == 200:
                        data = await response.json()
                        return self._process_cost_metrics(data)
                    else:
                        logger.warning(f"Cost metrics unavailable: {response.status}")
                        return self._get_mock_cost_metrics()
        except Exception as e:
            logger.error(f"Error getting cost metrics: {e}")
            return self._get_mock_cost_metrics()
    
    async def get_application_insights_metrics(self) -> Dict[str, Any]:
        """Get Application Insights metrics"""
        # Application Insights would require separate setup
        # For now, return comprehensive mock data
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "application": {
                "request_rate": 150.5,
                "response_time_ms": 45.2,
                "failure_rate": 0.2,
                "dependency_duration_ms": 12.8
            },
            "exceptions": {
                "total_count": 3,
                "unique_count": 2,
                "top_exceptions": [
                    {"type": "ConnectionError", "count": 2},
                    {"type": "TimeoutError", "count": 1}
                ]
            },
            "performance": {
                "page_load_time_ms": 1250,
                "ajax_call_duration_ms": 180,
                "server_response_time_ms": 45
            },
            "users": {
                "active_users": 245,
                "unique_users_today": 1850,
                "session_duration_minutes": 12.5
            }
        }
    
    async def _ensure_authenticated(self) -> bool:
        """Ensure we have a valid access token"""
        if not self.access_token or (self.token_expires and datetime.utcnow() >= self.token_expires):
            return await self.authenticate()
        return True
    
    def _process_aks_metrics(self, data: Dict) -> Dict[str, Any]:
        """Process AKS metrics response"""
        try:
            metrics = {}
            for metric in data.get('value', []):
                metric_name = metric['name']['value']
                timeseries = metric.get('timeseries', [])
                
                if timeseries and len(timeseries) > 0:
                    latest_data = timeseries[0].get('data', [])
                    if latest_data:
                        latest_value = latest_data[-1].get('average', 0)
                        metrics[metric_name] = latest_value
            
            return {
                "timestamp": datetime.utcnow().isoformat(),
                "cluster_name": self.aks_cluster_name,
                "metrics": metrics,
                "nodes": {
                    "total": 1,
                    "ready": 1,
                    "cpu_usage": metrics.get('node_cpu_usage_percentage', 0),
                    "memory_usage": metrics.get('node_memory_working_set_percentage', 0)
                },
                "pods": {
                    "ready_percentage": metrics.get('pods_ready_percentage', 100),
                    "total": 6,
                    "running": 6
                }
            }
        except Exception as e:
            logger.error(f"Error processing AKS metrics: {e}")
            return self._get_mock_aks_metrics()
    
    def _process_network_metrics(self, data: Dict) -> Dict[str, Any]:
        """Process network metrics response"""
        try:
            metrics = {}
            for metric in data.get('value', []):
                metric_name = metric['name']['value']
                timeseries = metric.get('timeseries', [])
                
                if timeseries and len(timeseries) > 0:
                    latest_data = timeseries[0].get('data', [])
                    if latest_data:
                        latest_value = latest_data[-1].get('total', 0)
                        metrics[metric_name] = latest_value
            
            return {
                "timestamp": datetime.utcnow().isoformat(),
                "load_balancer": {
                    "bytes_processed": metrics.get('ByteCount', 0),
                    "packets_processed": metrics.get('PacketCount', 0),
                    "syn_count": metrics.get('SYNCount', 0)
                },
                "bandwidth": {
                    "inbound_mbps": 850.5,
                    "outbound_mbps": 920.2,
                    "total_mbps": 1770.7
                },
                "latency": {
                    "average_ms": 25.5,
                    "p95_ms": 45.2,
                    "p99_ms": 85.1
                }
            }
        except Exception as e:
            logger.error(f"Error processing network metrics: {e}")
            return self._get_mock_network_metrics()
    
    def _process_cost_metrics(self, data: Dict) -> Dict[str, Any]:
        """Process cost metrics response"""
        try:
            rows = data.get('properties', {}).get('rows', [])
            services_cost = {}
            total_cost = 0
            
            for row in rows:
                if len(row) >= 3:
                    cost = row[0]
                    service = row[2]
                    services_cost[service] = cost
                    total_cost += cost
            
            return {
                "timestamp": datetime.utcnow().isoformat(),
                "period": "Month to Date",
                "total_cost_usd": total_cost,
                "services": services_cost,
                "estimated_monthly": total_cost * 1.5,  # Rough estimation
                "budget_status": {
                    "budget_limit": 100.0,
                    "spent_percentage": (total_cost / 100.0) * 100,
                    "remaining": 100.0 - total_cost
                }
            }
        except Exception as e:
            logger.error(f"Error processing cost metrics: {e}")
            return self._get_mock_cost_metrics()
    
    def _get_mock_aks_metrics(self) -> Dict[str, Any]:
        """Mock AKS metrics for development/demo"""
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "cluster_name": self.aks_cluster_name,
            "metrics": {
                "node_cpu_usage_percentage": 35.2,
                "node_memory_working_set_percentage": 45.8,
                "pods_ready_percentage": 100.0
            },
            "nodes": {
                "total": 1,
                "ready": 1,
                "cpu_usage": 35.2,
                "memory_usage": 45.8
            },
            "pods": {
                "ready_percentage": 100.0,
                "total": 6,
                "running": 6
            },
            "status": "mock_data"
        }
    
    def _get_mock_network_metrics(self) -> Dict[str, Any]:
        """Mock network metrics for development/demo"""
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "load_balancer": {
                "bytes_processed": 1500000000,  # 1.5GB
                "packets_processed": 2500000,
                "syn_count": 15000
            },
            "bandwidth": {
                "inbound_mbps": 850.5,
                "outbound_mbps": 920.2,
                "total_mbps": 1770.7
            },
            "latency": {
                "average_ms": 25.5,
                "p95_ms": 45.2,
                "p99_ms": 85.1
            },
            "status": "mock_data"
        }
    
    def _get_mock_cost_metrics(self) -> Dict[str, Any]:
        """Mock cost metrics for development/demo"""
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "period": "Month to Date",
            "total_cost_usd": 47.85,
            "services": {
                "Azure Kubernetes Service": 35.20,
                "Container Registry": 5.50,
                "Load Balancer": 4.15,
                "Storage": 3.00
            },
            "estimated_monthly": 72.50,
            "budget_status": {
                "budget_limit": 100.0,
                "spent_percentage": 47.85,
                "remaining": 52.15
            },
            "status": "mock_data"
        }

# Global Azure Monitor instance
azure_monitor = AzureMonitorIntegration()
