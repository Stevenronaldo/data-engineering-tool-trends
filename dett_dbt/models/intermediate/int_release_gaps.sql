with stable_releases as (

    select
        repo,
        id,
        tag_name,
        published_at
    from {{ ref('stg_raw_github__releases') }}
    where prerelease = false
      and published_at is not null

)

select
    repo,
    id,
    tag_name,
    published_at,
    timestamp_diff(
        published_at,
        lag(published_at) over (partition by repo order by published_at, id),
        day
    ) as days_since_previous_release
from stable_releases