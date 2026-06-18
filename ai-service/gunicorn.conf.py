import multiprocessing

# ── Binding ───────────────────────────────────────────────────────────────────
bind = "0.0.0.0:5000"

# ── Workers ───────────────────────────────────────────────────────────────────
# Keep workers low: each worker loads the 175 MB ResNet101 model into RAM.
# preload_app=True forks after loading → workers share the model in memory.
workers = 2
worker_class = "sync"
threads = 1

# Load the app (and the model) once before forking workers.
# This dramatically reduces Fargate memory usage.
preload_app = True

# ── Timeouts ──────────────────────────────────────────────────────────────────
# ResNet101 CPU inference can take a few seconds; give it room.
timeout = 120
keepalive = 5
graceful_timeout = 30

# ── Logging ───────────────────────────────────────────────────────────────────
# CloudWatch picks up stdout/stderr automatically in ECS.
accesslog = "-"
errorlog = "-"
loglevel = "info"
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s %(D)s'

# ── Security / limits ─────────────────────────────────────────────────────────
limit_request_line = 4096
limit_request_fields = 100
max_requests = 1000          # recycle workers after N requests (memory leak guard)
max_requests_jitter = 100
