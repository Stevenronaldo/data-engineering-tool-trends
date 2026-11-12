with source as (

    select * from {{ source('raw_github', 'forks') }}

),

ranked as (

    select
        repo,
        id,
        full_name,
        created_at,
        loaded_at,
        row_number() over (
            partition by repo, id
            order by loaded_at desc
        ) as row_num
    from source

)

select
    repo,
    id,
    full_name,
    created_at,
    loaded_at
from ranked
where row_num = 1