FROM python:3.6-slim as base

RUN \
    apt-get -y update && apt-get install && \
    apt install libpq-dev --no-install-recommends -y && \
    pip install -U pip micropipenv

FROM base as builder

WORKDIR /app
COPY Pipfile.lock Pipfile ./

ENV PIP_WHEEL_DIR=/wheelhouse
ENV BUILD_DEPS='g++ gcc git make build-essential'

RUN \
    apt-get install -y $BUILD_DEPS --no-install-recommends && \
    micropipenv requirements --no-dev > requirements.txt && \
    pip install -r requirements.txt && \
    pip wheel -r requirements.txt

FROM base

WORKDIR /app

COPY --from=builder /wheelhouse /wheelhouse
COPY --from=builder /app/* ./

RUN pip install \
    --no-index \
    --find-links=/wheelhouse \
    -r requirements.txt

COPY exchangerates exchangerates
EXPOSE 8080

ENTRYPOINT ["gunicorn", ",--worker-class", "sanic.worker.GunicornWorker"]
CMD ["exchangerates.app:app", "--max-requests", "1000"]
