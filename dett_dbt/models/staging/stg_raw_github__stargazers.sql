with source as (

    select * from {{ source('raw_github', 'stargazers_history') }}

),

ranked as (

    select
        repo,
        week,
        total as total_star,
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
    total_star,
    loaded_at
from ranked
where row_num = 1