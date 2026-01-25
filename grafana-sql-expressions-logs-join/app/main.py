#!/usr/bin/env python3
"""
Job simulator that generates start/end logs for asynchronous jobs.
Logs are exported via OpenTelemetry to an OTLP endpoint.
"""

import asyncio
import logging
import random
import uuid
import os

from opentelemetry import _logs
from opentelemetry.sdk._logs import LoggerProvider, LoggingHandler
from opentelemetry.sdk._logs.export import BatchLogRecordProcessor
from opentelemetry.exporter.otlp.proto.grpc._log_exporter import OTLPLogExporter
from opentelemetry.sdk.resources import Resource

# Configuration
OTLP_ENDPOINT = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://otel-lgtm:4317")
SERVICE_NAME = os.getenv("OTEL_SERVICE_NAME", "job-simulator")
JOB_START_INTERVAL = 10  # seconds between new jobs
JOB_MIN_DURATION = 10    # minimum job duration in seconds
JOB_MAX_DURATION = 120   # maximum job duration in seconds
ERROR_RATE = 0.05        # 5% of jobs end in error


def setup_logging() -> logging.Logger:
    """Configure OpenTelemetry logging with OTLP export."""
    resource = Resource.create({"service.name": SERVICE_NAME})

    logger_provider = LoggerProvider(resource=resource)
    _logs.set_logger_provider(logger_provider)

    exporter = OTLPLogExporter(endpoint=OTLP_ENDPOINT, insecure=True)
    logger_provider.add_log_record_processor(BatchLogRecordProcessor(exporter))

    handler = LoggingHandler(level=logging.INFO, logger_provider=logger_provider)

    logger = logging.getLogger("job_simulator")
    logger.setLevel(logging.INFO)
    logger.addHandler(handler)

    # Also log to console for visibility
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    console_handler.setFormatter(logging.Formatter("%(asctime)s - %(message)s"))
    logger.addHandler(console_handler)

    return logger


async def run_job(logger: logging.Logger, job_id: str) -> None:
    """Simulate a job: log start, wait, log end with status."""
    duration = random.uniform(JOB_MIN_DURATION, JOB_MAX_DURATION)

    # Log job start (logfmt syntax)
    logger.info(f'event=start job_id={job_id}')

    # Simulate work
    await asyncio.sleep(duration)

    # Determine outcome (5% error rate)
    status = "error" if random.random() < ERROR_RATE else "success"

    # Log job end (logfmt syntax)
    logger.info(f'event=end job_id={job_id} status={status} duration_seconds={round(duration, 2)}')


async def job_spawner(logger: logging.Logger) -> None:
    """Spawn new jobs at regular intervals."""
    while True:
        job_id = str(uuid.uuid4())[:8]  # Short UUID for readability
        asyncio.create_task(run_job(logger, job_id))

        # Add some jitter to the interval (8-12 seconds)
        interval = JOB_START_INTERVAL + random.uniform(-2, 2)
        await asyncio.sleep(interval)


async def main() -> None:
    """Main entry point."""
    logger = setup_logging()
    logger.info("event=startup msg=\"Job simulator starting\"")

    await job_spawner(logger)


if __name__ == "__main__":
    asyncio.run(main())
