with 
    calendar as (
        select * from {{ ref("int_calendar")}}
    ),
    stargazers as (
        select * from {{ ref("stg_raw_github__stargazers")}}
    ),
    commits_weekly as (
        select * from {{ ref("int_commits_weekly")}}
    ),
    forks_weekly as (
        select * from {{ ref("int_forks_weekly")}}
    ),
    releases_weekly as (
        select * from {{ ref("int_releases_weekly")}}
    ),
    repo_labels as (
        select * from {{ ref("repo_labels")}}
    ),
    joined as (
        select 
            cal.repo,
            rl.tool_name,
            rl.category,
            cal.week,
            coalesce(s.star_count,0) as star_count,
            coalesce(c.commits_count, 0) as commits_count,
            coalesce(f.forks_count, 0) as forks_count,
            coalesce(r.stable_release_count, 0) as stable_release_count,
            coalesce(r.prerelease_count, 0) as prerelease_count
        from calendar cal
        left join repo_labels rl
            on cal.repo = rl.repo
        left join commits_weekly c
            on cal.repo = c.repo and cal.week = c.week
        left join stargazers s
            on cal.repo = s.repo and cal.week = s.week
        left join forks_weekly f
            on cal.repo = f.repo and cal.week = f.week
        left join releases_weekly r
            on cal.repo = r.repo and cal.week = r.week
        where cal.week < timestamp_trunc(CURRENT_TIMESTAMP(), WEEK)

    ),
     with_first_week as (
        select
            *,
            min(case when star_count > 0 then week end)
                over (partition by repo) as first_star_week,
            min(case when commits_count > 0 then week end)
                over (partition by repo) as first_commit_week,
            min(case when stable_release_count > 0 then week end)
                over (partition by repo) as first_release_week      
        from joined
     ),

    final as (
        select
            repo,
            tool_name,
            category,
            week,
            star_count,
            sum(star_count) over (
                partition by repo order by week
                rows between unbounded preceding and current row
            ) as cumulative_stars,
            commits_count,
            sum(commits_count) over (
                partition by repo order by week
                rows between unbounded preceding and current row
            ) as cumulative_commits,
            forks_count,
            sum(forks_count) over (
                partition by repo order by week
                rows between unbounded preceding and current row
            ) as cumulative_forks,
            stable_release_count,
            prerelease_count,
            first_star_week,
            div(timestamp_diff(week, first_star_week, day), 7) as weeks_since_first_star,
            first_commit_week,
            div(timestamp_diff(week, first_commit_week, day), 7) as weeks_since_first_commit,
            first_release_week,
            div(timestamp_diff(week, first_release_week, day), 7) as weeks_since_first_release
        from with_first_week
    )

select * from final
