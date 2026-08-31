#!/usr/bin/env bash
# ==============================================================================
# AI Statement of Purpose (SOP) Generator - Installer for Linux & macOS
# ==============================================================================

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}  🎓 AI Statement of Purpose (SOP) Generator Setup  ${NC}"
echo -e "${CYAN}====================================================${NC}\n"

# 1. Locate Python 3
PYTHON_BIN=""
if command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python3"
elif command -v python >/dev/null 2>&1; then
    PYTHON_BIN="python"
else
    echo -e "${RED}[Error] Python 3 is not installed.${NC}"
    echo -e "Please install Python 3.9 or newer and try again."
    exit 1
fi

# Check Python version (>= 3.9)
PY_VERSION=$($PYTHON_BIN -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
PY_MAJOR=$($PYTHON_BIN -c "import sys; print(sys.version_info.major)")
PY_MINOR=$($PYTHON_BIN -c "import sys; print(sys.version_info.minor)")

if [ "$PY_MAJOR" -lt 3 ] || ([ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -lt 9 ]); then
    echo -e "${RED}[Error] Python 3.9+ is required (found Python $PY_VERSION).${NC}"
    exit 1
fi
echo -e "${GREEN}[✓] Found Python $PY_VERSION ($PYTHON_BIN)${NC}"

# 2. Check if inside repository or clone it
REPO_URL="https://github.com/intelQong/markitdown-sop-generator.git"
TARGET_DIR="markitdown-sop-generator"

if [ -f "src/sop_engine.py" ]; then
    PROJECT_DIR="$(pwd)"
elif [ -d "$TARGET_DIR" ] && [ -f "$TARGET_DIR/src/sop_engine.py" ]; then
    PROJECT_DIR="$(pwd)/$TARGET_DIR"
    cd "$PROJECT_DIR"
else
    echo -e "${BLUE}[*] Cloning repository from ${REPO_URL}...${NC}"
    if ! command -v git >/dev/null 2>&1; then
        echo -e "${RED}[Error] Git is required to clone the repository.${NC}"
        echo -e "Please install git or download the repository manually."
        exit 1
    fi
    git clone "$REPO_URL" "$TARGET_DIR"
    cd "$TARGET_DIR"
    PROJECT_DIR="$(pwd)"
fi

echo -e "${GREEN}[✓] Working directory: $PROJECT_DIR${NC}"

# 3. Create virtual environment
VENV_DIR="$PROJECT_DIR/.venv"
if [ ! -d "$VENV_DIR" ]; then
    echo -e "${BLUE}[*] Creating Python virtual environment in .venv...${NC}"
    $PYTHON_BIN -m venv "$VENV_DIR" || {
        echo -e "${YELLOW}[!] Failed to create venv with $PYTHON_BIN -m venv.${NC}"
        echo -e "${YELLOW}[!] On Ubuntu/Debian, you may need: sudo apt install python3-venv${NC}"
        exit 1
    }
fi
echo -e "${GREEN}[✓] Virtual environment ready at .venv${NC}"

# 4. Activate virtual environment and install dependencies
# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

echo -e "${BLUE}[*] Upgrading pip and installing required packages...${NC}"
pip install --upgrade pip --quiet
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt --quiet
elif [ -f "src/requirements.txt" ]; then
    pip install -r src/requirements.txt --quiet
fi

# Optional editable install for CLI entrypoint
pip install -e . --quiet

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}  ✨ Installation Completed Successfully!          ${NC}"
echo -e "${GREEN}====================================================${NC}\n"

echo -e "To get started, activate the virtual environment:\n"
echo -e "  ${CYAN}cd $(pwd)${NC}"
echo -e "  ${CYAN}source .venv/bin/activate${NC}\n"
echo -e "Run the CLI engine:"
echo -e "  ${CYAN}sop-engine --help${NC}   (or: ${CYAN}python src/sop_engine.py --help${NC})\n"
echo -e "Ingest applicant files:"
echo -e "  ${CYAN}sop-engine --ingest \"path/to/applicant_folder\" --output-md \"applicant_context.md\"${NC}\n"
echo -e "Export SOP to Word (.docx):"
echo -e "  ${CYAN}sop-engine --export-docx \"final_sop.txt\" --docx-out \"SOP.docx\" --name \"Applicant Name\" --course \"Degree\" --country \"Country\"${NC}\n"
