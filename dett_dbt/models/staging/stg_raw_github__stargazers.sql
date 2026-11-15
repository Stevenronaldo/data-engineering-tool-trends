with source as (

    select * from {{ source('raw_github', 'stargazers_history') }}

),

ranked as (

    select
        repo,
        timestamp_seconds(week) as week,
        total as star_count,
        loaded_at,
        row_number() over (
            partition by repo, week
            order by loaded_at desc
        ) as row_num
    from source

)

select
    repo,
    week,
    star_count,
    loaded_at
from ranked
where row_num = 1