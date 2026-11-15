WITH source as (

    SELECT * FROM {{ ref('stg_raw_github__releases') }}
    WHERE published_at is not null
)

SELECT
    repo,
    datetime_trunc(published_at, week) as week,
    COUNTIF(prerelease is false) as stable_release_count,
    COUNTIF(prerelease is true) as prerelease_count

FROM source
GROUP BY repo, week