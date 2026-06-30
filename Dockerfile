# Base image Python
FROM python:3.10-slim

# Set working directory utama di dalam container
WORKDIR /app

# Copy file requirements
COPY requirement.txt .

# Install library Python
RUN pip install --no-cache-dir -r requirement.txt

# Copy seluruh source code dari laptop ke dalam container
COPY . .

# Perintah untuk menjalankan script utama ETL Anda
CMD ["bash", "run_db_pipeline.sh"]