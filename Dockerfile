# Stage 1: Build the project
FROM ubuntu:latest AS builder

# Set environment variable to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages for building
RUN apt update && \
    apt-get install -y git python3 build-essential imagemagick libx11-dev libxext-dev libfreetype6-dev libpng-dev libjpeg-dev pkg-config gcc-arm-none-eabi binutils-arm-none-eabi zip unzip

# Clone the Upsilon repository and build the project
RUN git clone --recursive https://github.com/UpsilonNumworks/Upsilon.git && \
    cd Upsilon && \
    git switch upsilon-dev && \
    git clone https://github.com/emscripten-core/emsdk.git && \
    cd emsdk && \
    ./emsdk install 1.40.1 && \
    ./emsdk activate 1.40.1 && \
    . ./emsdk_env.sh && \
    cd .. && \
    make clean && \
    make PLATFORM=simulator TARGET=web OMEGA_USERNAME="Upsilon" -j$(nproc) && \
    cd output/release/simulator/web && \
    unzip -o epsilon.zip && \
    rm epsilon.zip

# Stage 2: Serve the built files using nginx
FROM nginx:alpine

# Copy the built files from the builder stage
COPY --from=builder /Upsilon/output/release/simulator/web/ /usr/share/nginx/html/

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 80 to the outside world
EXPOSE 80

# Start nginx when the container launches
CMD ["nginx", "-g", "daemon off;"]