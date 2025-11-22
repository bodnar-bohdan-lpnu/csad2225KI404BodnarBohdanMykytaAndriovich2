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
