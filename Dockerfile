FROM python:3.11-slim

WORKDIR /app

COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/ .
COPY backend/plugins/ ./plugins/

EXPOSE 18791

CMD ["python", "app.py"]
