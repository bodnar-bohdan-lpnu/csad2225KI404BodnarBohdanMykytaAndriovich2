#include <gtest/gtest.h>

#include "math_operations.h"

TEST(MathOperationsTest, AddsPositiveNumbers) {
    EXPECT_EQ(add(2, 3), 5);
}

TEST(MathOperationsTest, HandlesNegativeNumbers) {
    EXPECT_EQ(add(-4, -6), -10);
    EXPECT_EQ(add(-4, 6), 2);
}

TEST(MathOperationsTest, HandlesZero) {
    EXPECT_EQ(add(0, 0), 0);
    EXPECT_EQ(add(0, 5), 5);
    EXPECT_EQ(add(7, 0), 7);
}

TEST(MathOperationsTest, HandlesLargeNumbers) {
    EXPECT_EQ(add(1'000'000'000, 500'000'000), 1'500'000'000);
}

int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
