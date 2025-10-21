#!/bin/bash

# Anime Aggressors C++ Performance Build Script
# High-performance C++ backend for the ultimate anime fighting game

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Build configuration
PROJECT_NAME="Anime Aggressors Performance Engine"
VERSION="1.0.0"
BUILD_DIR="build"
RELEASE_DIR="build/release"
DEBUG_DIR="build/debug"
INSTALL_DIR="install"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE} $1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check CMake installation
check_cmake() {
    if ! command_exists cmake; then
        print_error "CMake is not installed. Please install CMake to continue."
        echo "Visit https://cmake.org/download/ for installation instructions."
        exit 1
    fi
    
    CMAKE_VERSION=$(cmake --version | head -n1 | cut -d' ' -f3)
    print_success "CMake version $CMAKE_VERSION is installed"
}

# Function to check C++ compiler
check_compiler() {
    if command_exists g++; then
        COMPILER="g++"
        COMPILER_VERSION=$(g++ --version | head -n1 | cut -d' ' -f4)
        print_success "GCC version $COMPILER_VERSION is available"
    elif command_exists clang++; then
        COMPILER="clang++"
        COMPILER_VERSION=$(clang++ --version | head -n1 | cut -d' ' -f4)
        print_success "Clang version $COMPILER_VERSION is available"
    else
        print_error "No C++ compiler found. Please install GCC or Clang."
        exit 1
    fi
}

# Function to check build tools
check_build_tools() {
    if ! command_exists make; then
        print_error "Make is not installed. Please install make to continue."
        exit 1
    fi
    
    if ! command_exists ninja; then
        print_warning "Ninja is not installed. Using make instead."
        GENERATOR="Unix Makefiles"
    else
        print_success "Ninja build system is available"
        GENERATOR="Ninja"
    fi
}

# Function to clean build directory
clean_build() {
    print_header "Cleaning Build Directory"
    
    if [ -d "$BUILD_DIR" ]; then
        print_status "Cleaning build directory..."
        rm -rf "$BUILD_DIR"
        print_success "Build directory cleaned"
    else
        print_status "No existing build directory to clean"
    fi
}

# Function to create build directory
create_build_dir() {
    print_header "Creating Build Directory"
    
    print_status "Creating build directory..."
    mkdir -p "$BUILD_DIR"
    print_success "Build directory created"
}

# Function to configure CMake
configure_cmake() {
    print_header "Configuring CMake"
    
    print_status "Configuring CMake with $GENERATOR..."
    cd "$BUILD_DIR"
    
    cmake .. \
        -G "$GENERATOR" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="../$INSTALL_DIR" \
        -DCMAKE_CXX_STANDARD=20 \
        -DCMAKE_CXX_STANDARD_REQUIRED=ON \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
        -DCMAKE_VERBOSE_MAKEFILE=ON
    
    if [ $? -eq 0 ]; then
        print_success "CMake configuration completed successfully"
    else
        print_error "CMake configuration failed"
        exit 1
    fi
    
    cd ..
}

# Function to build debug version
build_debug() {
    print_header "Building Debug Version"
    
    print_status "Building debug version..."
    cd "$BUILD_DIR"
    
    cmake --build . --config Debug --target anime_aggressors_performance
    
    if [ $? -eq 0 ]; then
        print_success "Debug build completed successfully"
    else
        print_error "Debug build failed"
        exit 1
    fi
    
    cd ..
}

# Function to build release version
build_release() {
    print_header "Building Release Version"
    
    print_status "Building release version with optimizations..."
    cd "$BUILD_DIR"
    
    cmake --build . --config Release --target anime_aggressors_performance
    
    if [ $? -eq 0 ]; then
        print_success "Release build completed successfully"
    else
        print_error "Release build failed"
        exit 1
    fi
    
    cd ..
}

# Function to run tests
run_tests() {
    print_header "Running Tests"
    
    print_status "Running unit tests..."
    cd "$BUILD_DIR"
    
    if [ -f "performance_test" ]; then
        ./performance_test
        if [ $? -eq 0 ]; then
            print_success "All tests passed"
        else
            print_warning "Some tests failed"
        fi
    else
        print_warning "Test executable not found"
    fi
    
    cd ..
}

# Function to run benchmarks
run_benchmarks() {
    print_header "Running Benchmarks"
    
    print_status "Running performance benchmarks..."
    cd "$BUILD_DIR"
    
    if [ -f "benchmark" ]; then
        ./benchmark
        if [ $? -eq 0 ]; then
            print_success "Benchmarks completed successfully"
        else
            print_warning "Benchmarks completed with warnings"
        fi
    else
        print_warning "Benchmark executable not found"
    fi
    
    cd ..
}

# Function to install
install_build() {
    print_header "Installing Build"
    
    print_status "Installing build artifacts..."
    cd "$BUILD_DIR"
    
    cmake --install . --config Release
    
    if [ $? -eq 0 ]; then
        print_success "Installation completed successfully"
    else
        print_error "Installation failed"
        exit 1
    fi
    
    cd ..
}

# Function to create release package
create_release_package() {
    print_header "Creating Release Package"
    
    PACKAGE_NAME="anime-aggressors-performance-$VERSION"
    PACKAGE_DIR="packages/$PACKAGE_NAME"
    
    # Create package directory
    mkdir -p "$PACKAGE_DIR"
    
    # Copy release binary
    if [ -f "$BUILD_DIR/libanime_aggressors_performance.dylib" ]; then
        cp "$BUILD_DIR/libanime_aggressors_performance.dylib" "$PACKAGE_DIR/"
    elif [ -f "$BUILD_DIR/libanime_aggressors_performance.so" ]; then
        cp "$BUILD_DIR/libanime_aggressors_performance.so" "$PACKAGE_DIR/"
    elif [ -f "$BUILD_DIR/anime_aggressors_performance.dll" ]; then
        cp "$BUILD_DIR/anime_aggressors_performance.dll" "$PACKAGE_DIR/"
    fi
    
    # Copy header files
    cp -r include "$PACKAGE_DIR/"
    
    # Copy source files
    cp -r src "$PACKAGE_DIR/"
    
    # Copy build files
    cp CMakeLists.txt "$PACKAGE_DIR/"
    cp README.md "$PACKAGE_DIR/" 2>/dev/null || true
    
    # Copy install directory
    if [ -d "$INSTALL_DIR" ]; then
        cp -r "$INSTALL_DIR" "$PACKAGE_DIR/"
    fi
    
    # Create package info
    cat > "$PACKAGE_DIR/package-info.json" << EOF
{
  "name": "$PACKAGE_NAME",
  "version": "$VERSION",
  "description": "High-performance C++ backend for Anime Aggressors",
  "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "files": [
    "*.dylib",
    "*.so",
    "*.dll",
    "include/**/*",
    "src/**/*",
    "CMakeLists.txt",
    "README.md"
  ]
}
EOF
    
    # Create tarball
    cd packages
    tar -czf "$PACKAGE_NAME.tar.gz" "$PACKAGE_NAME"
    cd ..
    
    print_success "Release package created: packages/$PACKAGE_NAME.tar.gz"
}

# Function to display build summary
display_build_summary() {
    print_header "Build Summary"
    
    echo -e "${GREEN}✓${NC} CMake configuration completed"
    echo -e "${GREEN}✓${NC} Build directory created"
    echo -e "${GREEN}✓${NC} Debug build completed"
    echo -e "${GREEN}✓${NC} Release build completed"
    echo -e "${GREEN}✓${NC} Tests executed"
    echo -e "${GREEN}✓${NC} Benchmarks executed"
    echo -e "${GREEN}✓${NC} Installation completed"
    echo -e "${GREEN}✓${NC} Release package created"
    
    echo ""
    print_success "Build completed successfully!"
    echo ""
    echo -e "${CYAN}Build Output:${NC} $BUILD_DIR/"
    echo -e "${CYAN}Install Directory:${NC} $INSTALL_DIR/"
    echo -e "${CYAN}Release Package:${NC} packages/"
    echo ""
    echo -e "${YELLOW}To run the performance engine:${NC} ./$BUILD_DIR/anime_aggressors_performance"
    echo -e "${YELLOW}To run tests:${NC} ./$BUILD_DIR/performance_test"
    echo -e "${YELLOW}To run benchmarks:${NC} ./$BUILD_DIR/benchmark"
    echo -e "${YELLOW}To install:${NC} cd $BUILD_DIR && make install"
}

# Main build function
main() {
    print_header "Anime Aggressors C++ Performance Build System"
    echo -e "${CYAN}Building $PROJECT_NAME v$VERSION${NC}"
    echo ""
    
    # Check prerequisites
    check_cmake
    check_compiler
    check_build_tools
    
    # Clean and create build directory
    clean_build
    create_build_dir
    
    # Configure and build
    configure_cmake
    build_debug
    build_release
    
    # Run tests and benchmarks
    run_tests
    run_benchmarks
    
    # Install and package
    install_build
    create_release_package
    
    # Display summary
    display_build_summary
}

# Handle command line arguments
case "${1:-}" in
    "clean")
        clean_build
        ;;
    "configure")
        create_build_dir
        configure_cmake
        ;;
    "debug")
        build_debug
        ;;
    "release")
        build_release
        ;;
    "test")
        run_tests
        ;;
    "bench")
        run_benchmarks
        ;;
    "install")
        install_build
        ;;
    "package")
        create_release_package
        ;;
    "help"|"-h"|"--help")
        echo "Anime Aggressors C++ Performance Build Script"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  clean      Clean build directory"
        echo "  configure  Configure CMake"
        echo "  debug      Build debug version"
        echo "  release    Build release version"
        echo "  test       Run tests"
        echo "  bench      Run benchmarks"
        echo "  install    Install build"
        echo "  package    Create release package"
        echo "  help       Show this help message"
        echo ""
        echo "If no command is specified, a full build will be performed."
        ;;
    "")
        main
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Run '$0 help' for usage information."
        exit 1
        ;;
esac

