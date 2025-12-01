FROM registry.access.redhat.com/ubi9 AS jar-builder

RUN dnf install -y zip && dnf clean all

COPY keycloak-scripts/ /tmp/keycloak-scripts/
RUN cd /tmp/keycloak-scripts && \
    zip -r /opt/keycloak-scripts.jar .

FROM quay.io/keycloak/keycloak:26.3 AS builder

ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
ENV KC_FEATURES=scripts:v1
ENV KC_DB=mariadb

# Copy the built scripts jar
COPY --chown=keycloak:keycloak --chmod=644 --from=jar-builder /opt/keycloak-scripts.jar /opt/keycloak/providers/

# Add other custom providers (e.g. Apple IDP)
COPY --chown=keycloak:keycloak --chmod=644 keycloak-providers/*.jar /opt/keycloak/providers/

# Build optimized server with providers baked in
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:26.3

# Copy the optimized server from the builder stage
COPY --from=builder /opt/keycloak/ /opt/keycloak/

# Copy secrets2env helper script with execute permissions
COPY --chmod=755 secrets2env.sh /usr/local/bin/secrets2env.sh
