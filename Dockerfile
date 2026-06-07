FROM zmkfirmware/zmk-dev-arm:stable

RUN mkdir -p /workspace \
  && chown -R ubuntu:ubuntu /workspace

USER ubuntu
WORKDIR /workspace

COPY --chown=ubuntu:ubuntu entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Copy the west manifest so the workspace is initialized with both ZMK
# and YADS (zmk-dongle-screen). Without this, YADS is only available at
# runtime and `west build` fails with "shield not found: dongle_screen".
COPY --chown=ubuntu:ubuntu config/west.yml config/west.yml

# Initialize the west workspace using the user's manifest.
# This fetches ZMK v0.3.0, Zephyr, all HALs, and YADS in one shot.
# Expensive step (~2 GB download) — cached by Docker layer.
RUN west init -l config \
  && west update \
  && west zephyr-export

# Route all `docker compose run` commands through the build script.
# Usage: docker compose run --rm make [dongle|left|right|reset|all]
# For a shell: docker compose run --rm --entrypoint bash make
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
