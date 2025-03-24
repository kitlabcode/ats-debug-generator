# Use the official Ubuntu 22.04 image as the base
FROM ubuntu:22.04

# Set noninteractive mode for apt
ARG DEBIAN_FRONTEND=noninteractive

# Update package lists and install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    trafficserver \
    curl \
    wget \
    sed \
    ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Enable the plugins (assuming they are available in the default installation)
RUN sed -i 's/# *plugin.config/plugin.config/' /etc/trafficserver/records.config
RUN echo "xdebug.so" >> /etc/trafficserver/plugin.config
RUN echo "generator.so" >> /etc/trafficserver/plugin.config

# Create the local state directory for Traffic Server
RUN mkdir -p /run/trafficserver && \
    chown -R trafficserver:trafficserver /run/trafficserver

# Update the local state directory configuration
RUN sed -i "s|proxy.config.local_state_dir.*|proxy.config.local_state_dir STRING /run/trafficserver|" /etc/trafficserver/records.config

# Add rules to remap.config
RUN echo "map http://localhost/ http://127.0.0.1/ @plugin=generator.so" > /etc/trafficserver/remap.config && \
    echo "map http://ats-debug-generator/ http://127.0.0.1/ @plugin=generator.so" >> /etc/trafficserver/remap.config

# Fix the debug mode configuration
RUN sed -i "/proxy.config.diags.debug.enabled/d" /etc/trafficserver/records.config && \
    echo "CONFIG proxy.config.diags.debug.enabled INT 1" >> /etc/trafficserver/records.config

# Fix the server ports configuration
RUN sed -i "/proxy.config.http.server_ports/d" /etc/trafficserver/records.config && \
    echo "CONFIG proxy.config.http.server_ports STRING 80 443:ssl" >> /etc/trafficserver/records.config

# Expose ports 80 and 443
EXPOSE 80
EXPOSE 443

# Start Traffic Server when the container runs
CMD ["/usr/bin/traffic_server"]