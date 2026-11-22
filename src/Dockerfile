FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

COPY requirements-loader.txt .
RUN pip install -r requirements-loader.txt

COPY github_fetch.py repositories.py ./

RUN useradd --create-home appuser \
    && mkdir -p /app/data \
    && chown -R appuser:appuser /app
USER appuser

CMD ["python", "github_fetch.py"]