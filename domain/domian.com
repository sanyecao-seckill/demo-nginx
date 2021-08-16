server {
        listen 7081;
        location /sayhello{
            default_type text/plain;
            proxy_pass http://backend;
        }
}
