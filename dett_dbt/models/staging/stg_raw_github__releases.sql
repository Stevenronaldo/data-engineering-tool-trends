with source as (

    select * from {{ source('raw_github', 'releases') }}

)

select
    repo,
    id,
    tag_name,
    published_at,
    prerelease,
    loaded_at
from source