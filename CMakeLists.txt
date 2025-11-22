cmake_minimum_required(VERSION 3.16)
project(csad2225KI404BodnarBohdanMykytaAndriovich2 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

include(FetchContent)
include(CTest)

add_library(math_operations
    math_operations.cpp
)

target_include_directories(math_operations
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
)

add_executable(${PROJECT_NAME}
    main.cpp
)

target_link_libraries(${PROJECT_NAME}
    PRIVATE
        math_operations
)

if (BUILD_TESTING)
    set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)

    FetchContent_Declare(
        googletest
        URL https://github.com/google/googletest/archive/refs/tags/v1.14.0.zip
    )

    FetchContent_MakeAvailable(googletest)

    add_executable(unit_tests
        tests/unit_tests.cpp
    )

    target_link_libraries(unit_tests
        PRIVATE
            GTest::gtest_main
            math_operations
    )

    target_include_directories(unit_tests
        PRIVATE
            ${CMAKE_CURRENT_SOURCE_DIR}
    )

    include(GoogleTest)
    gtest_discover_tests(unit_tests)
endif()
