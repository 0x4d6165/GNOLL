#!/usr/bin/env python3

from util import Mock, roll


def test_d6():
    r = "d6"
    result = roll(r, mock_mode=Mock.RETURN_CONSTANT, mock_const=3)
    assert result == 3


def test_d66():
    r = "#DSIXTYSIX=(d6*10)+d6;@DSIXTYSIX"
    result = roll(r, mock_mode=Mock.RETURN_CONSTANT, mock_const=3)
    assert result == 33


def test_d666():
    r = "#DSIXSIXSIX=(d6*100)+(d6*10)+d6;@DSIXTYSIX"
    result = roll(r, mock_mode=Mock.RETURN_CONSTANT, mock_const=3)
    assert result == 333
