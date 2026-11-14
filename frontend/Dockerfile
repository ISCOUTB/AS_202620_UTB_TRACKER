# App web de UTB Tracker: se compila con Flutter y se sirve con nginx.
# API_BASE_URL es la dirección del backend VISTA DESDE EL NAVEGADOR (no desde el contenedor).
FROM ghcr.io/cirruslabs/flutter:stable AS compilar

ARG API_BASE_URL=http://localhost:8000
WORKDIR /src
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get --enforce-lockfile
COPY . .
RUN flutter build web --release --no-wasm-dry-run --dart-define=API_BASE_URL=${API_BASE_URL}

FROM nginx:1.27-alpine
COPY --from=compilar /src/build/web /usr/share/nginx/html
EXPOSE 80
