# 🚀 Project Update Overview

A cleaner, lighter, and more dynamic challenge environment setup.

from 5.6 GB to 2.97 GB

1️⃣ Rust & Go Removed from Base Image

To reduce Docker image size and improve deployment efficiency:

Rust ❌
Go ❌
build-essential ❌

are no longer pre-installed in the base machine.


Uncomment if needed in the docker file 

Benefits
Smaller base image
Faster builds
Lower storage usage
Challenge-specific dependencies only
⚡ Dynamic Challenge Launcher

start_challenge.sh now dynamically detects and launches the challenge runner script.

Instead of hardcoded filenames, the system automatically searches for executable bash challenge files.


The challenge package itself now contains:

Dependency installation
Setup logic
Runtime configuration

This keeps the base machine lightweight and modular.

# 🧠 New Startup Flow

start.sh now fully initializes the environment automatically.

Startup Sequence
```
start.sh
 ├── Starts VNC
 ├── Starts noVNC
 └── Launches challenge
```
This provides:

Fully automated startup
Cleaner orchestration
Better challenge isolation
Improved user experience

# 🏗️ Architecture Philosophy

The project now follows a more modular design:

Component	Responsibility
Base Machine	Generic runtime environment
Challenge Package	Dependencies + logic
start.sh	Machine orchestration
start_challenge.sh	Dynamic challenge execution

# 🔥 Result

✅ Smaller images

✅ Faster deployment

✅ Easier scaling

✅ Better maintainability

✅ Cleaner challenge packaging

# 📦 Recommended Challenge Structure
```
challenge/
├── Dockerfile
├── start.sh
├── start_challenge.sh
├── run_challenge
└── challenge_files/
```



```
#web3-hamonis


docker build -t hamonis:base .


docker run -d --name hamonis-base -p 5901:5901 -p 8080:8080 hamonis:base

```
