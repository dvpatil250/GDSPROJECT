# ---- Stage 1: Build ----
FROM python:3.9 AS builder

# Set working directory
WORKDIR /app

# Copy only the requirements file first (faster builds with Docker cache)
COPY app/requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir awslambdaric  #  Correct package for AWS Lambda runtime

# ---- Stage 2: Run ----
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Set AWS region as an environment variable
ENV AWS_REGION=us-east-1

# Copy installed dependencies from the builder stage
COPY --from=builder /usr/local/lib/python3.9/site-packages/ /usr/local/lib/python3.9/site-packages/
COPY --from=builder /usr/local/bin/ /usr/local/bin/

# Copy the entire application folder
COPY app/ .

#  Correct Lambda CMD syntax
CMD ["python", "-m", "awslambdaric", "main.lambda_handler"]

