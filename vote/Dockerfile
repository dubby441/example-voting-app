# base defines a base stage that uses the official python runtime base image
FROM python:3.11-slim@sha256:e88e9763f943ec1834f992a4b51e0f24500486803e8bc534e5767af9ea65f6ce AS base

# Add curl for healthcheck
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

# Set the application directory
WORKDIR /usr/local/app

# Install our requirements.txt
COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Create an unprivileged user for the application.
RUN useradd --create-home --uid 10001 appuser

FROM base AS dev

RUN pip install --no-cache-dir watchdog

ENV FLASK_ENV=development
ENV PORT=8080

USER 10001:10001

CMD ["python", "app.py"]

FROM base AS final

COPY --chown=10001:10001 . .

ENV PORT=8080

USER 10001:10001

EXPOSE 8080

CMD ["gunicorn", "app:app", "-b", "0.0.0.0:8080", "--log-file", "-", "--access-logfile", "-", "--workers", "4", "--keep-alive", "0"]