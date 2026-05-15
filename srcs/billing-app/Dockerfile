FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8080

CMD ["python3", "server.py"]