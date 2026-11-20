select distinct_weeks
from (
    select count(distinct as_of_week) as distinct_weeks
    from {{ ref('fct_repo_summary') }}
)
where distinct_weeks > 1