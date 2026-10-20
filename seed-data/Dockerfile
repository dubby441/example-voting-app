FROM python:3.9-slim@sha256:2d97f6910b16bd338d3060f261f53f144965f755599aab1acda1e13cf1731b1b

# Install Apache Bench
RUN apt-get update \
    && apt-get install -y --no-install-recommends apache2-utils \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --uid 10001 appuser

WORKDIR /seed

COPY --chown=10001:10001 . .

# Generate the data files required by Apache Bench
RUN python make-data.py \
    && chmod +x /seed/generate-votes.sh

USER 10001:10001

CMD ["/seed/generate-votes.sh"]