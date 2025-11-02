# Minimal Fluentd image for OMEGA logging
FROM fluent/fluentd:v1.16-debian

USER root
# Install any extra packages if needed
# RUN apt-get update && apt-get install -y tzdata && rm -rf /var/lib/apt/lists/*

COPY fluent.conf /fluentd/etc/fluent.conf

# Ensure proper permissions
RUN chown fluent:fluent /fluentd/etc/fluent.conf

USER fluent
CMD ["fluentd", "-c", "/fluentd/etc/fluent.conf", "-v"]