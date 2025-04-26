FROM amazonlinux:2023

# Install dependencies
RUN yum update -y && \
    yum install -y unzip curl && \
    yum clean all

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

# Install aws-nuke
RUN curl -L -o aws-nuke.tar.gz https://github.com/ekristen/aws-nuke/releases/download/v3.51.1/aws-nuke-v3.51.1-linux-amd64.tar.gz && \
    tar xzvf aws-nuke.tar.gz && \
    mv aws-nuke-v3.51.1-linux-amd64 /usr/local/bin/aws-nuke && \
    chmod +x /usr/local/bin/aws-nuke && \
    rm aws-nuke.tar.gz

# Copy function code
COPY app.py /var/task/
WORKDIR /var/task

# Set the CMD to the handler
CMD [ "app.handler" ]