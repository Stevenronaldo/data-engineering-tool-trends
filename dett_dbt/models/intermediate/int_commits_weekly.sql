WITH source as (

    SELECT * FROM {{ ref('stg_raw_github__commits') }}
    where committed_at is not null
)

SELECT
    repo,
    datetime_trunc(committed_at, week) as week,
    count(*) as commits_count
FROM source 
GROUP BY repo, week