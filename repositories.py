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

ENDPOINTS =[#name, per_page, schema, date_column, write_mode
    [
        "stargazers/history", 30,
        {
            "week":"INT64", 
            "total": "INT64"
         },
         "week", "WRITE_APPEND"
        ],
    [
        "forks", 100,
        {
            "id": "INT64", 
            "full_name": "STRING",
            "created_at": "TIMESTAMP"
        },
        "created_at", "WRITE_APPEND"
    ],
     
    [
        "releases", 100, 
        {
            "id": "INT64",
            "tag_name": "STRING",
            "published_at": "TIMESTAMP",
            "prerelease": "BOOL"
        },
        None, "WRITE_TRUNCATE"
    ],
    [
        "commits", 100,
        {
            "sha": "STRING",
            "commit.committer.date": "TIMESTAMP"
         },
        "commit.committer.date", "WRITE_APPEND"
    ]
]

    