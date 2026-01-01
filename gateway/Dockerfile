FROM python:3.11-alpine

# Install docker CLI
RUN apk add --no-cache docker-cli

WORKDIR /app

COPY api.py /app/

RUN chmod +x /app/api.py

EXPOSE 8080

CMD ["python3", "-u", "/app/api.py"]
