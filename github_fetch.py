from urllib import response
from datetime import datetime, time, timezone
import requests
import os
import json
from urllib3 import Retry
from google.cloud import bigquery
from dotenv import load_dotenv
load_dotenv()

from repositories import GITHUB_REPOS, ENDPOINTS

def make_session(total=3, backoff_factor=1):
    retry = Retry(total= total, 
            backoff_factor= backoff_factor, 
            status_forcelist=[429, 500, 502, 503, 504],
            allowed_methods=["GET"],
            raise_on_status=False
            )
    session = requests.Session()
    session.mount("https://", requests.adapters.HTTPAdapter(max_retries=retry))
    return session

def get_json(session, url, params=None):
    response = session.get(url, params=params, timeout=10)

    if response.status_code != 200:
        raise Exception(f"HTTP {response.status_code} - {response.text[:200]}")
    
    return response.json(), int(response.headers.get("X-RateLimit-Remaining"))

def get_path(item, path):
    for key in path.split("."):
        item = (item or {}).get(key)
    return item

session = make_session()
session.headers.update({
    "Authorization": f"Bearer {os.environ['GITHUB_TOKEN']}",
    "Accept": "application/vnd.github+json",
    "X-GitHub-Api-Version": "2026-03-10",
})

client = bigquery.Client(project=os.getenv("GCP_PROJECT"))
dataset = client.get_dataset(os.getenv("BQ_DATASET"))

os.makedirs("data", exist_ok=True)

run_ts = datetime.now(timezone.utc).isoformat()     


for endpoint, per_page, schema in ENDPOINTS[:1]:
    print(f"-----Fetching {endpoint} with {per_page} per page-----")
    path = f"data/{endpoint.replace('/', '_')}.jsonl"
    written = 0

    schema_fields = [bigquery.SchemaField(path.replace(".", "_"), typ) for path, typ in schema.items()]
    schema_fields += [bigquery.SchemaField("repo", "STRING"), bigquery.SchemaField("loaded_at", "TIMESTAMP")]

    with open(path, "w") as f:
        for repo in GITHUB_REPOS:
            print(f"Fetching {repo} for {endpoint}")
            URL = f"https://api.github.com/repos/{repo}/{endpoint}"
            page_count = 1
            while True:
                data, rate_limit_remaining = get_json(session, URL, params={"page": page_count, "per_page": per_page})
                
                if rate_limit_remaining < 100:
                    print(f"-----Rate limit remaining: {rate_limit_remaining}. stop fetching for now.-----")
                    time.sleep(3600)  # sleep for 60 minutes (filled every 60 mins) if rate limit is low
                elif rate_limit_remaining % 100 == 0:
                    print(f"....Rate limit remaining: {rate_limit_remaining}.")

                if data == []:
                    break
                for item in data:
                    trim_item = {path.replace(".", "_"): get_path(item, path) for path in schema}
                    trim_item["repo"] = repo
                    trim_item["loaded_at"] = run_ts
                    f.write(json.dumps(trim_item) + "\n")
                    written += 1
                page_count += 1
            print(f"..Fetched {written} rows for {repo} for {endpoint}.")

    table_id = f"{dataset.project}.{dataset.dataset_id}.{endpoint.replace('/', '_')}"
    job_config = bigquery.LoadJobConfig(
        schema=schema_fields,
        source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
    )
    with open(path, "rb") as f:
        job = client.load_table_from_file(f, table_id, job_config=job_config)
    job.result()
    print(table_id, job.output_rows)
    if job.output_rows == written:
        print(f"Successfully loaded {written} rows into {table_id}.")
        os.remove(path)
    else:
        print(f"Row mismatch: file {written}, loaded {job.output_rows}. Keeping {path} for inspection.")
