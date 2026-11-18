with
    weekly as (
        select * from {{ ref('fct_repo_weekly') }}
    ),

    anchor as (
        select
            max(week) as last_week,
            timestamp_sub(max(week), interval 84 day) as cut_12w,
            timestamp_sub(max(week), interval 168 day) as cut_24w,
            timestamp_sub(max(week), interval 364 day) as cut_52w
        from weekly
    ),

    ranked as (
        select
            *,
            row_number() over (partition by repo order by week desc) as rn
        from weekly
    ),

    latest as (
        select
            repo,
            tool_name,
            category,
            week as as_of_week,
            cumulative_stars as stars_total,
            cumulative_forks as forks_total,
        from ranked
        where rn = 1
    ),

    windows as (
        select
            w.repo,
            sum(if(w.week > a.cut_12w, w.star_count, 0)) as stars_last_12w,
            sum(if(w.week > a.cut_24w and w.week <= a.cut_12w, w.star_count, 0)) as stars_prev_12w,
            sum(if(w.week > a.cut_52w, w.star_count, 0)) as stars_last_52w,
            sum(if(w.week > a.cut_12w, w.commits_count, 0)) as commits_last_12w,
            sum(if(w.week > a.cut_52w, w.commits_count, 0)) as commits_last_52w,
            sum(if(w.week > a.cut_52w, w.forks_count, 0)) as forks_last_52w,
            sum(if(w.week > a.cut_52w, w.stable_release_count, 0)) as stable_releases_last_52w
        from weekly w
        cross join anchor a
        group by w.repo
    ),

    latest_commit as (
        select repo, max(committed_at) as latest_commit_at
        from {{ ref('stg_raw_github__commits') }}
        group by repo
    ),

    latest_release as (
        select repo, max(published_at) as latest_stable_release_at
        from {{ ref('stg_raw_github__releases') }}
        where prerelease = false
        group by repo
    ),

    cadence as (
        select
            g.repo,
            avg(g.days_since_previous_release) as avg_days_between_releases,
            avg(if(
                timestamp_trunc(g.published_at, week) > a.cut_52w
                and timestamp_trunc(g.published_at, week) <= a.last_week,
                g.days_since_previous_release,
                null
            )) as avg_days_between_releases_52w
        from {{ ref('int_release_gaps') }} g
        cross join anchor a
        group by g.repo
    )

select
    l.repo,
    l.tool_name,
    l.category,
    l.as_of_week,
    l.stars_total,
    l.forks_total,
    w.stars_last_52w,
    safe_divide(w.stars_last_52w, l.stars_total - w.stars_last_52w) as stars_growth_rate_52w,
    w.stars_last_12w,
    w.stars_prev_12w,
    w.stars_last_12w - w.stars_prev_12w as stars_change_12w,
    w.commits_last_12w,
    w.commits_last_52w,
    w.forks_last_52w,
    w.stable_releases_last_52w,
    lc.latest_commit_at,
    lr.latest_stable_release_at,
    c.avg_days_between_releases,
    c.avg_days_between_releases_52w
from latest l
left join windows w on l.repo = w.repo
left join latest_commit lc on l.repo = lc.repo
left join latest_release lr on l.repo = lr.repo
left join cadence c on l.repo = c.repo