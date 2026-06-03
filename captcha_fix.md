## Error

<img width="954" height="755" alt="Playwright_error_sunoapimgr" src="https://github.com/user-attachments/assets/a873e1de-ba6a-410c-b33e-6743d3223384" />

## Fix

```bash
# Create environment
conda create -n suno-manager python=3.11 -y
conda activate suno-manager

# Install dependencies
pip install -r requirements.txt

# Install ffmpeg (if not already installed)
conda install -c conda-forge ffmpeg -y
# or: brew install ffmpeg (macOS)
# or: sudo apt install ffmpeg (Ubuntu/Debian)
```

```bash
# If using Conda:
conda activate suno-manager

# Or if using venv:
# source venv/bin/activate

# Start the application
python app.py

# Or run directly with uvicorn (with hot-reload):
uvicorn app:app --host 0.0.0.0 --port 8080 --reload
```

## Error Persisting ?

```bash
Browser logs:

╔════════════════════════════════════════════════════════════════════════════════════════════════╗
║ Looks like you launched a headed browser without having a XServer running.                     ║
║ Set either 'headless: true' or use 'xvfb-run <your-playwright-app>' before running Playwright. ║
║                                                                                                ║
║ <3 Playwright Team                                                                             ║
╚════════════════════════════════════════════════════════════════════════════════════════════════╝
Call log:
```
