with all_weeks as (
        select repo, week from {{ref("int_commits_weekly")}}
        union distinct
        select repo, week from {{ref("stg_raw_github__stargazers")}}
        union distinct
        select repo, week from {{ref("int_forks_weekly")}}
        union distinct
        select repo, week from {{ref("int_releases_weekly")}}
    ),

    bounds as (
        select
            repo,
            min(week) as first_week,
            max(week) as last_week
        from all_weeks
        group by repo
    ),

    calendar as (
        select
            b.repo,
            week
        from bounds b,
            unnest(generate_timestamp_array(
                b.first_week,
                b.last_week,
                interval 7 day
            )) as week
    )

select * from calendar