ARG PLAYWRIGHT_PYTHON_IMAGE=mcr.microsoft.com/playwright/python:v1.49.1-jammy
FROM ${PLAYWRIGHT_PYTHON_IMAGE}

WORKDIR /app

# Create non-root user for security
RUN useradd -m -u 1001 appuser

# Install dependencies with caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && \
    rm -rf /tmp/* ~/.cache

# Copy application code
COPY app ./app

# Set ownership
RUN chown -R appuser:appuser /app

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=10s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8788/health')" || exit 1

EXPOSE 8788
USER appuser

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8788"]
