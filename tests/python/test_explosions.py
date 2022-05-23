#!/usr/bin/env python3

import pytest
from util import roll, Mock


@pytest.mark.parametrize("r,out",[
    ("d3!", 7), #{3},{3},{1}
    ("d5!", 3)
])
def test_explosion(r, out):
    result = roll(r, mock_mode=Mock.RETURN_CONSTANT_TWICE_ELSE_CONSTANT_ONE, mock_const=3)
    assert result == out


@pytest.mark.parametrize("r,out",[
    ("2d3!", 8),   #{3,3},{1,1}
    ("2d5!", 6)    #{3,3}
])
def test_multi_dice_explosion(r, out):
    result = roll(r, mock_mode=Mock.RETURN_CONSTANT_TWICE_ELSE_CONSTANT_ONE, mock_const=3)
    assert result == out


@pytest.mark.parametrize("r,out",[
    ("d3!o", 6),
])
def test_explosion_only_once(r, out):
    result = roll(r, mock_mode=Mock.RETURN_CONSTANT_TWICE_ELSE_CONSTANT_ONE, mock_const=3)
    assert result == out

@pytest.mark.parametrize("r,out",[
    ("d4!p", 10),
])
def test_explosion_penetrate(r, out):
    result = roll(r, mock_mode=Mock.RETURN_DECREMENTING, mock_const=4)
    assert result == out
