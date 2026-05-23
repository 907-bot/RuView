import multiprocessing
import os

workers = int(os.getenv('WORKERS', max(2, multiprocessing.cpu_count() * 2)))
threads = int(os.getenv('GUNICORN_THREADS', 2))
bind = '0.0.0.0:8000'
worker_class = 'uvicorn.workers.UvicornWorker'
timeout = 120
