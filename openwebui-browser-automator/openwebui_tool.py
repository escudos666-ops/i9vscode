"""
Open WebUI Tool: Browser form filler via local Playwright service.

1) Open WebUI -> Workspace -> Tools -> Create Tool
2) Paste this file
3) Set valves:
   - automator_url: http://host.docker.internal:8788
   - automator_token: same token as AUTOMATOR_API_TOKEN
"""

from typing import Any, Dict, List, Optional
import json
import requests
from pydantic import BaseModel, Field


class Tools:
    class Valves(BaseModel):
        automator_url: str = Field(
            default="http://host.docker.internal:8788",
            description="Browser automator base URL",
        )
        automator_token: str = Field(
            default="change-me-token",
            description="Bearer token for browser automator",
        )

    def __init__(self):
        self.valves = self.Valves()

    def fill_form(
        self,
        url: str,
        fields_json: str,
        submit_selector: str = "",
        wait_for_selector: str = "",
        wait_after_ms: int = 1000,
        timeout_ms: int = 15000,
    ) -> str:
        """
        Fill a form on a website and optionally submit it.

        :param url: Target page URL (must be allowlisted on automator)
        :param fields_json: JSON array, e.g.
            [
              {"selector":"#email","value":"john@doe.com","action":"type"},
              {"selector":"#password","value":"secret","action":"type"},
              {"selector":"#terms","value":"true","action":"check"}
            ]
        :param submit_selector: CSS selector for submit button
        :param wait_for_selector: CSS selector to wait for after submit
        :param wait_after_ms: Additional wait time after actions
        :param timeout_ms: Per-page timeout
        :return: JSON result with final URL and title
        """
        try:
            fields: List[Dict[str, Any]] = json.loads(fields_json)
        except Exception as e:
            return f"Invalid fields_json: {e}"

        payload: Dict[str, Any] = {
            "url": url,
            "fields": fields,
            "submit_selector": submit_selector or None,
            "wait_for_selector": wait_for_selector or None,
            "wait_after_ms": wait_after_ms,
            "timeout_ms": timeout_ms,
        }
        headers = {
            "Authorization": f"Bearer {self.valves.automator_token}",
            "Content-Type": "application/json",
        }
        endpoint = self.valves.automator_url.rstrip("/") + "/fill-form"

        try:
            response = requests.post(endpoint, json=payload, headers=headers, timeout=90)
            response.raise_for_status()
            return json.dumps(response.json(), ensure_ascii=False)
        except requests.HTTPError:
            return f"HTTP {response.status_code}: {response.text}"
        except Exception as e:
            return f"Request failed: {e}"
