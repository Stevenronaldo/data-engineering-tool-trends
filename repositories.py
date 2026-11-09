GITHUB_REPOS =[
    "apache/airflow",
    "dagster-io/dagster",
    "PrefectHQ/prefect",
    "dbt-labs/dbt-core",
    "SQLMesh/sqlmesh",
    "hashicorp/terraform",
    "opentofu/opentofu",
    "apache/spark",
    "duckdb/duckdb",
    "pola-rs/polars"
]

ENDPOINTS =[#name, per_page, schema
    [
        "stargazers/history", 30,
        {
            "week":"INT64", 
            "total": "INT64"
         }
        ],
    [
        "forks", 100,
        {
            "id": "INT64", 
            "full_name": "STRING",
            "created_at": "TIMESTAMP"
        }
    ],
     
    [
        "releases", 100, 
        {
            "id": "INT64",
            "tag_name": "STRING",
            "published_at": "TIMESTAMP",
            "prerelease": "BOOL"
        }
    ],
    [
        "commits", 100,
        {
            "sha": "STRING",
            "commit.committer.date": "TIMESTAMP"
         }
    ]
]

    