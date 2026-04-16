# Use the official AWS Lambda Python 3.11 base image
FROM public.ecr.aws/lambda/python:3.11

# Set the working directory
WORKDIR ${LAMBDA_TASK_ROOT}

# Install OS-level dependencies required for compiling psycopg2
RUN yum update -y && \
    yum install -y \
    gcc \
    postgresql-devel \
    cargo \
    && yum clean all

# Copy the admin-specific requirements and install dependencies
# We build from the root directory context
COPY services/admin/requirements.txt ./services/admin/requirements.txt
RUN pip install --upgrade pip setuptools wheel && pip install --no-cache-dir -r ./services/admin/requirements.txt

# Copy the core shared package
COPY core/ ./core/

# Copy the admin service specific code preserving the module path
COPY services/admin/ ./services/admin/

# Set the entrypoint to the Mangum handler
CMD [ "services.admin.handler.lambda_handler" ]
