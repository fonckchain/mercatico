# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copy Flutter app
COPY mercatico_app/pubspec.* ./
RUN flutter pub get

COPY mercatico_app/ ./
RUN flutter build web --release --web-renderer canvaskit

# Stage 2: Serve with nginx
FROM nginx:alpine

# Copy built web app
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
