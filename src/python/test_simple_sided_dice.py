#!/usr/bin/env python3

from unittest import mock
import pytest
import csv
import os
import sys
from util import test_roll

def test_random_test_roll():
    # Prove Random test_roll Is Working
    a,b,c,d = False
    for x in range(100):
        result = test_roll("d4")
        assert(result > 0)
        assert(result < 5)
        if result == 1:
            a = True
        if result == 2:
            b = True
        if result == 3:
            c = True
        if result == 4:
            d = True
    assert(a)
    assert(b)
    assert(c)
    assert(d)

def test_space_removal():
    result = test_roll("   d    4   ")
    assert(result > 0)
    assert(result < 5)

def test_negative_test_roll():
    result = test_roll("-d4")
    assert(result > -5)
    assert(result < 0)

def test_non_test_rolling_test_roll():
    result = test_roll("d0")
    assert(result == 0)
    result = test_roll("d1")
    assert(result == 1)
    result = test_roll("-d0")
    assert(result == 0)
    result = test_roll("0d4")
    assert(result == 0)


def test_bad_simple_test_rolls():
    with pytest.raises(Exception):
        # Just "Dice" does not make sense
        test_roll("d")
    with pytest.raises(Exception):
        # Just "Dice" does not make sense
        test_roll("d2d")
    with pytest.raises(Exception):
        # See above
        test_roll("1d")
    with pytest.raises(Exception):
        # Negative Sides does not make sense
        test_roll("d-1")
    with pytest.raises(Exception):
        # Negative Sides does not make sense
        test_roll("-1d-1")

def test_dice_numbers():
    result = test_roll("2d6", mock_random=4)
    assert(result, 8)