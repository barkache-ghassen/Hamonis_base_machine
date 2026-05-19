🚀 Project Update Overview

A cleaner, lighter, and more dynamic challenge environment setup.

✨ What's New
1️⃣ Rust & Go Removed from Base Image

To reduce Docker image size and improve deployment efficiency:

Rust ❌
Go ❌

are no longer pre-installed in the base machine.

If your challenge requires them, simply uncomment the installation section inside the Dockerfile.

Example
# Uncomment if needed
# RUN apt install golang-go -y
# RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
Benefits
Smaller base image
Faster builds
Lower storage usage
Challenge-specific dependencies only
⚡ Dynamic Challenge Launcher

start_challenge.sh now dynamically detects and launches the challenge runner script.

Instead of hardcoded filenames, the system automatically searches for executable bash challenge files.

Example
run_challenge

The challenge package itself now contains:

Dependency installation
Setup logic
Runtime configuration

This keeps the base machine lightweight and modular.

🧠 New Startup Flow

start.sh now fully initializes the environment automatically.

Startup Sequence
start.sh
 ├── Starts VNC
 ├── Starts noVNC
 └── Launches challenge

This provides:

Fully automated startup
Cleaner orchestration
Better challenge isolation
Improved user experience
🏗️ Architecture Philosophy

The project now follows a more modular design:

Component	Responsibility
Base Machine	Generic runtime environment
Challenge Package	Dependencies + logic
start.sh	Machine orchestration
start_challenge.sh	Dynamic challenge execution
🔥 Result

✅ Smaller images
✅ Faster deployment
✅ Easier scaling
✅ Better maintainability
✅ Cleaner challenge packaging
✅ More professional infrastructure

📦 Recommended Challenge Structure
challenge/
├── Dockerfile
├── start.sh
├── start_challenge.sh
├── run_challenge
└── challenge_files/
🛠️ Migration Notes

Older challenges may require:

Moving dependency installation into the challenge itself
Adding a launcher file like:
run_challenge
Uncommenting Rust/Go installation if needed

```
#web3-hamonis


docker build -t hamonis:base .


docker run -d --name hamonis-base -p 5901:5901 -p 8080:8080 hamonis:base

```
