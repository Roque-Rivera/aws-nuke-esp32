FROM amazonlinux:2023

# Install dependencies
RUN yum update -y && \
    yum install -y unzip tar python3 python3-pip && \
    yum clean all

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

# Install aws-nuke
RUN curl -L -o aws-nuke.tar.gz https://github.com/ekristen/aws-nuke/releases/download/v3.51.1/aws-nuke-v3.51.1-linux-amd64.tar.gz && \
    tar xzvf aws-nuke.tar.gz && \
    mv aws-nuke /usr/local/bin/aws-nuke && \
    chmod +x /usr/local/bin/aws-nuke && \
    rm -rf aws-nuke.tar.gz

# Install Python dependencies
RUN pip3 install --no-cache-dir boto3 awslambdaric

# Set up the function directory
WORKDIR /var/task

# Copy function code and entrypoint script
COPY app.py /var/task/
COPY entrypoint.sh /var/task/

# Make entrypoint executable
RUN chmod +x /var/task/entrypoint.sh

# Set the entrypoint for Lambda
ENTRYPOINT ["/var/task/entrypoint.sh"]