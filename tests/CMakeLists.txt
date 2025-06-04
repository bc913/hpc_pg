include(FetchContent)

# For Windows: Prevent overriding the parent project's compiler/linker settings
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
set(BUILD_GMOCK ON CACHE BOOL "" FORCE)
set(INSTALL_GTEST OFF CACHE BOOL "" FORCE)

FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/15460959cbbfa20e66ef0b5ab497367e47fc0a04.zip
)

FetchContent_MakeAvailable(googletest)

set(_HPC_PG_TESTS_TARGET "${_HPC_TARGET_BASE_NAME}_tests")
project(${_HPC_PG_TESTS_TARGET} LANGUAGES CXX)


set(_HPC_PG_TESTS_SOURCE_FILES)
list(APPEND _HPC_PG_TESTS_SOURCE_FILES
    hpc_tests.cpp
)

add_executable(${_HPC_PG_TESTS_TARGET} "")
target_sources(${_HPC_PG_TESTS_TARGET}
    PRIVATE
        ${_HPC_PG_TESTS_SOURCE_FILES}
)

# target_include_directories(${_BELIK_TESTS_TARGET}
#     PRIVATE
#         $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
# )

target_link_libraries(${_HPC_PG_TESTS_TARGET} 
    PUBLIC 
        GTest::gtest_main
)

target_compile_definitions(${_HPC_PG_TESTS_TARGET} 
    PRIVATE
        HPC_PG_TEST_FLOAT_TOLERANCE=0.0001
        HPC_PG_TEST_DOUBLE_TOLERANCE=0.000001
)

include(GoogleTest)
set(CMAKE_GTEST_DISCOVER_TESTS_DISCOVERY_MODE PRE_TEST)
gtest_discover_tests(${_HPC_PG_TESTS_TARGET})