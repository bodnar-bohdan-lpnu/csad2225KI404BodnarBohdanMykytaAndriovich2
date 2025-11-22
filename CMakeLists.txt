cmake_minimum_required(VERSION 3.16)
project(csad2225KI404BodnarBohdanMykytaAndriovich2 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(Threads REQUIRED)
find_package(GTest QUIET)

if (NOT GTest_FOUND)
    include(FetchContent)
    set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
    FetchContent_Declare(
        googletest
        URL https://github.com/google/googletest/archive/refs/tags/v1.14.0.zip
    )
    FetchContent_MakeAvailable(googletest)
endif()

include(CTest)
enable_testing()

add_library(math_operations STATIC
    math_operations.cpp
)

target_include_directories(math_operations
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
)

add_executable(test_app
    main.cpp
)

target_link_libraries(test_app
    PRIVATE
        math_operations
)

add_executable(unit_tests
    tests/unit_tests.cpp
)

target_link_libraries(unit_tests
    PRIVATE
        math_operations
        GTest::gtest
        Threads::Threads
)

target_include_directories(unit_tests
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
)

add_test(NAME unit_tests COMMAND unit_tests)

add_custom_target(run_tests
    COMMAND ${CMAKE_CTEST_COMMAND} -C $<CONFIG> --output-on-failure
    DEPENDS unit_tests
)
