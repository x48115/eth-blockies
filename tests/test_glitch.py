import pytest

from brownie.convert import to_bytes


@pytest.fixture()
def gov(accounts):
    return accounts[0]


@pytest.fixture()
def alice(accounts):
    return accounts[1]


@pytest.fixture()
def bob(accounts):
    return accounts[2]


@pytest.fixture()
def glitch(Glitch, Random, Hex, ImageMap, Color, Base64, gov):
    Hex.deploy({"from": gov})
    ImageMap.deploy({"from": gov})
    Color.deploy({"from": gov})
    Random.deploy({"from": gov})
    Base64.deploy({"from": gov})
    return Glitch.deploy({"from": gov})


def test_generate(glitch, alice):
    glitch.get({"from": alice})
    print(glitch.tokenURI(1))
    image = glitch.images(1)
    with open("glitch.bmp", "bw") as f:
        f.write(to_bytes(image, type_str="bytes"))
