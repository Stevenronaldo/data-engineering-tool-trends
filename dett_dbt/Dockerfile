FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    DBT_SEND_ANONYMOUS_USAGE_STATS=false \
    DBT_PROFILES_DIR=/app \
    DBT_TARGET_PATH=/tmp/dbt_target \
    DBT_LOG_PATH=/tmp/dbt_logs

WORKDIR /app

COPY requirements-dbt.txt .
RUN pip install -r requirements-dbt.txt

COPY . .
RUN dbt deps && rm -rf /tmp/dbt_logs /tmp/dbt_target

RUN useradd --create-home appuser \
    && chown -R appuser:appuser /app
USER appuser

CMD ["sh", "-c", "dbt source freshness --target cloud && dbt build --target cloud"]