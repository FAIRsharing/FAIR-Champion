environment 'production'

# Nginx connects to Puma on the same host.
bind 'tcp://127.0.0.1:4567'

# Each worker has its own pool of five request threads.
workers 2
threads 5, 5
