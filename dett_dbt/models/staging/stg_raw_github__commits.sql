with source as (

    select * from {{ source('raw_github', 'commits') }}

),

ranked as (

    select
        repo,
        sha,
        commit_committer_date as committed_at,
        loaded_at,
        row_number() over (
            partition by repo, sha
            order by loaded_at desc
        ) as row_num
    from source

)

select
    repo,
    sha,
    committed_at,
    loaded_at
from ranked
where row_num = 1