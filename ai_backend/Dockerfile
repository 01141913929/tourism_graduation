# Use the official AWS Lambda Python 3.11 base image
FROM public.ecr.aws/lambda/python:3.11

# Set the working directory (automatically set to /var/task by the base image)
WORKDIR ${LAMBDA_TASK_ROOT}

# Install OS-level dependencies required for compiling some python packages like psycopg2
RUN yum update -y && \
    yum install -y \
    gcc \
    postgresql-devel \
    cargo \
    && yum clean all

# Copy the requirements file and install dependencies
COPY requirements.txt .
RUN pip install --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt && \
    python -c "from mangum import Mangum; print('✅ mangum OK')" && \
    python -c "import psycopg2; print('✅ psycopg2 OK')" && \
    python -c "import boto3; print('✅ boto3 OK')"

# Copy the application code
COPY . ${LAMBDA_TASK_ROOT}/

# Set the entrypoint to the AWS handler inside our api folder
CMD [ "api.aws_websocket_handler.lambda_handler" ]
