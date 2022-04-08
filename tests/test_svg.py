import pytest
import codecs
from brownie.convert import to_bytes

seed = "0xE7eD6747FaC5360f88a2EFC03E00d25789F69291"


@pytest.fixture()
def svg(Svg, Color, ImageMap, Hex, Random, Base64, gov):
    Hex.deploy({"from": gov})
    Color.deploy({"from": gov})
    ImageMap.deploy({"from": gov})
    Random.deploy({"from": gov})
    Base64.deploy({"from": gov})
    return Svg.deploy({"from": gov})


def test_generate_svg(svg):
    image = svg.generateSvg(seed)
    print(image)

    # TODO: Fix busted SVG
    with open("blocky.svg", "w") as f:
        f.write(image)
