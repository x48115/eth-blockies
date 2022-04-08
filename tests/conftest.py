import pytest


@pytest.fixture()
def gov(accounts):
    return accounts[0]
