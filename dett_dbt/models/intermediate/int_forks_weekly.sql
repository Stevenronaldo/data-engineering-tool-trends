WITH source as (

    SELECT * FROM {{ ref('stg_raw_github__forks') }}
    WHERE created_at is not null
)

SELECT
    repo,
    datetime_trunc(created_at, week) as week,
    count(*) as forks_count
FROM source
GROUP BY repo, week