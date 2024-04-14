server {
  listen 80;
  listen [::]:80;
  listen 443 ssl http2;
  listen [::]:443 ssl http2;
  {{ssl_certificate_key}}
  {{ssl_certificate}}
  {{server_name}}
  {{root}}

  {{nginx_access_log}}
  {{nginx_error_log}}

  if ($scheme != "https") {
    rewrite ^ https://$host$uri permanent;
  }

  location @reverse_proxy {
    proxy_pass {{reverse_proxy_url}};
    # Timeout if the real server is dead
    proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;

    # Proxy Connection Settings
    proxy_buffers 32 4k;
    proxy_connect_timeout 240;
    proxy_headers_hash_bucket_size 128;
    proxy_headers_hash_max_size 1024;
    proxy_http_version 1.1;
    proxy_read_timeout 240;
    proxy_redirect http:// $scheme://;
    proxy_send_timeout 240;

    # Proxy Cache and Cookie Settings
    proxy_cache_bypass $cookie_session;
    #proxy_cookie_path / "/; Secure"; # enable at your own risk, may break certain apps
    proxy_no_cache $cookie_session;
    # Proxy Header Settings
    proxy_set_header Connection $connection_upgrade;
    proxy_set_header Early-Data $ssl_early_data;
    proxy_set_header Host $host;
    proxy_set_header Proxy "";
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Method $request_method;
    proxy_set_header X-Forwarded-Port $server_port;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Server $host;
    proxy_set_header X-Forwarded-Ssl on;
    proxy_set_header X-Forwarded-Uri $request_uri;
    proxy_set_header X-Original-Method $request_method;
    proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
    proxy_set_header X-Real-IP $remote_addr;
  }

  {{settings}}

  add_header Cache-Control no-transform;

  index index.html;

  location ^~ /.well-known {
    auth_basic off;
    allow all;
    try_files $uri @reverse_proxy;
  }

  location / {
    try_files $uri @reverse_proxy;
  }
}    
