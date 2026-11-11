from datetime import datetime, timezone, timedelta
import requests
import os
import json
from urllib3 import Retry
from google.cloud import bigquery
from google.api_core.exceptions import NotFound
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

def get_watermarks(client, endpoint, date_column, project, dataset):
    sql = f"""
        SELECT repo, max({date_column.replace(".", "_")}) as 
        watermark FROM `{project}.{dataset}.{endpoint}`
        group by repo
    """
    try:
        rows = client.query(sql).result()
    except NotFound:
        print(f"{endpoint} not found, treating as first run")
        return {}
    return {row.repo: row.watermark for row in rows}

def to_comparable(value, bq_type):
    if bq_type == "TIMESTAMP":
        return datetime.fromisoformat(value)
    return value

session = make_session()
session.headers.update({
    "Authorization": f"Bearer {os.environ['GITHUB_TOKEN']}",
    "Accept": "application/vnd.github+json",
    "X-GitHub-Api-Version": "2026-03-10",
})

PROJECT = os.getenv("GCP_PROJECT")
DATASET = os.getenv("BQ_DATASET")

SINCE_MARGIN = timedelta(days=1)  # Margin to avoid missing data due to time zone differences

client = bigquery.Client(project=PROJECT)
dataset = client.get_dataset(DATASET)

os.makedirs("data", exist_ok=True)

run_ts = datetime.now(timezone.utc).isoformat()     

for endpoint, per_page, schema, date_column, write_mode in ENDPOINTS:
    print(f"-----Fetching {endpoint} with {per_page} per page-----")
    endpoint_path = endpoint.replace('/', '_')

    date_key = date_column.replace(".", "_") if date_column else None
    date_type = schema[date_column] if date_column else None

    file_path = f"data/{endpoint_path}.jsonl"
    written = 0

    if date_column:
        watermarks = get_watermarks(client, endpoint_path, date_column, PROJECT, DATASET)
    else:
        watermarks = {}

    schema_fields = [bigquery.SchemaField(path.replace(".", "_"), typ) for path, typ in schema.items()]
    schema_fields += [bigquery.SchemaField("repo", "STRING"), bigquery.SchemaField("loaded_at", "TIMESTAMP")]

    with open(file_path, "w") as f:
        for repo in GITHUB_REPOS:
            print(f"....Fetching {repo} for {endpoint}")
            watermark = watermarks.get(repo, None)
            print(f"....last fetched for {repo} is {watermark}")
            URL = f"https://api.github.com/repos/{repo}/{endpoint}"
            page_count = 1
            repo_written = 0

            if endpoint == "commits" and watermark:
                since = (watermark - SINCE_MARGIN).strftime("%Y-%m-%dT%H:%M:%SZ")
            else:
                since = None

            while True:
                data, rate_limit_remaining = get_json(session, URL, params={"page": page_count, "per_page": per_page, "since": since})
                
                if rate_limit_remaining < 100:
                    raise RuntimeError(
                        f"Rate limit low ({rate_limit_remaining}) while fetching {repo} for {endpoint}. "
                        "Stopping before load; rerun after the limit resets."
                        )
                elif rate_limit_remaining % 100 == 0:
                    print(f"....Rate limit remaining: {rate_limit_remaining}.")

                if data == []:
                    break

                for item in data:
                    trim_item = {field.replace(".", "_"): get_path(item, field) for field in schema}
                    trim_item["repo"] = repo
                    trim_item["loaded_at"] = run_ts
                    row_time = to_comparable(trim_item[date_key], date_type) if date_key else None
                    if write_mode == "WRITE_TRUNCATE" or watermark is None or row_time >= watermark:
                        f.write(json.dumps(trim_item) + "\n")
                        written += 1
                        repo_written += 1
                
                if write_mode != "WRITE_TRUNCATE" and watermark is not None and row_time < watermark and since is None:
                    print(f"....Reached watermark for {repo} for {endpoint}. Stopping fetch.")
                    break

                page_count += 1
            print(f"....Fetched {repo_written} rows for {repo} for {endpoint}.")

    if written == 0:
        print(f"-----No new rows to load for {endpoint}. Skipping load.-----")
        continue

    table_id = f"{dataset.project}.{dataset.dataset_id}.{endpoint.replace('/', '_')}"
    job_config = bigquery.LoadJobConfig(
        schema=schema_fields,
        source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
        write_disposition=write_mode,
    )
    with open(file_path, "rb") as f:
        job = client.load_table_from_file(f, table_id, job_config=job_config)
    job.result()
    if job.output_rows == written:
        print(f"-----Successfully loaded {written} rows into {table_id}-----")
        os.remove(file_path)
    else:
        print(f"-----Row mismatch: file {written}, loaded {job.output_rows}. Keeping {file_path} for inspection.-----")
