cmake_minimum_required(VERSION 3.25.0 FATAL_ERROR)

project(hpc_pg LANGUAGES CXX)

#-------------------
# Options
#-------------------
option(HPC_PG_BUILD_TESTS "Enable unit tests" ON)

#https://github.com/Yousif-CS/concurrency/blob/main/README.md

#-------------------
# Include
#-------------------
set(HPC_PG_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
set(CONAN_PACKAGE_PATH "${CMAKE_SOURCE_DIR}/conan_packages")
list(APPEND CMAKE_MODULE_PATH ${HPC_PG_MODULE_PATH} ${CONAN_PACKAGE_PATH})

# System
include(GNUInstallDirs)
# User


#-------------------
# Settings
#-------------------
set(_HPC_TARGET_NAME ${PROJECT_NAME})

# Common
#-------------------
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_DEBUG_POSTFIX "d")
set(CMAKE_SKIP_INSTALL_ALL_DEPENDENCY ON)

# C++
#-------------------
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

#-------------------
# Preprocessor macros
#-------------------


#-------------------
# Source
#-------------------
add_subdirectory(src)

#-------------------
# Tests
#-------------------
if(HPC_PG_BUILD_TESTS)
    MESSAGE(STATUS "========== CONFIGURING TESTS... ==========")
    enable_testing()
    include(CTest)
    add_subdirectory(tests)
endif()