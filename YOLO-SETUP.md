# YOLO Object Detection Setup

## Quick Start

### 1. Build and Start YOLO Service

```bash
# Option A: Use pre-built image
docker-compose up -d yolo-api

# Option B: Build custom image
docker build -f Dockerfile.yolo -t yolo-api:latest .
docker-compose up -d yolo-api
```

### 2. Check if Running

```bash
curl http://localhost:8000/health
```

### 3. List Available Models

```bash
curl http://localhost:8000/models
```

## API Endpoints

### Health Check
```bash
curl http://localhost:8000/health
```

### Detect Objects in Image
```bash
curl -X POST http://localhost:8000/detect \
  -F "file=@image.jpg" \
  -F "model=yolov8n"
```

**Parameters:**
- `file`: Image file (JPG, PNG)
- `model`: One of `yolov8n`, `yolov8s`, `yolov8m`, `yolov8l`, `yolov8x`

**Response:**
```json
{
  "detections": [
    {
      "class": "person",
      "confidence": 0.95,
      "bbox": [100, 150, 200, 300]
    }
  ],
  "count": 1,
  "model": "yolov8n"
}
```

### List Models
```bash
curl http://localhost:8000/models
```

## CLI Tool

Use `yolo-cli.sh` for easy command-line access (Linux/macOS):

```bash
# Single image detection
./yolo-cli.sh detect photo.jpg
./yolo-cli.sh detect photo.jpg yolov8m

# Batch processing
./yolo-cli.sh batch ./images
./yolo-cli.sh batch ./images yolov8l

# Check service
./yolo-cli.sh health

# List models
./yolo-cli.sh models
```

## Model Comparison

| Model | Speed | Accuracy | Memory | Best For |
|-------|-------|----------|--------|----------|
| yolov8n | Fastest | Lower | 1-2GB | Real-time, edge devices |
| yolov8s | Fast | Good | 2-3GB | Quick detection |
| yolov8m | Medium | Better | 3-4GB | Balanced |
| yolov8l | Slow | High | 4-6GB | High accuracy |
| yolov8x | Slowest | Highest | 6-8GB | Maximum accuracy |

## Python Integration

```python
import requests
import json

# Upload image and detect
with open('image.jpg', 'rb') as f:
    files = {'file': f}
    params = {'model': 'yolov8n'}
    response = requests.post('http://localhost:8000/detect', 
                            files=files, 
                            params=params)
    
detections = response.json()
print(f"Found {detections['count']} objects")
for det in detections['detections']:
    print(f"  {det['class']}: {det['confidence']:.2f}")
```

## Docker Compose Configuration

YOLO service is configured with:
- **Port:** 8000
- **Memory limit:** 4GB (configurable)
- **Auto-restart:** Yes
- **Health check:** Every 30 seconds
- **Model cache:** `/root/.cache/yolov8`
- **Input directory:** `./yolo_input`
- **Output directory:** `./yolo_output`

## Reduce Memory Usage

If you need to save memory:

1. **Use nano model (yolov8n):** Fastest, lowest memory
2. **Disable GPU:** Set `CUDA_VISIBLE_DEVICES=-1` in docker-compose.yml
3. **Lower memory limit:** Reduce from 4GB to 2GB in compose

## Troubleshooting

**Service won't start:**
```bash
docker logs yolo-service
```

**API not responding:**
```bash
# Check if container is running
docker ps | grep yolo

# Restart service
docker-compose restart yolo-api
```

**Out of memory:**
```bash
# Check current usage
docker stats yolo-service

# Reduce model size in API calls
# Use yolov8n instead of yolov8x
```

## Stop Service

```bash
docker-compose stop yolo-api
```
