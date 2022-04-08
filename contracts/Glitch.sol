// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./Base64.sol";
import "./Color.sol";
import "./Random.sol";
import "./ImageMap.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Glitch is ERC721("Glitch", "GLITCH") {
    using Counters for Counters.Counter;

    uint32 constant size = 10;

    uint32 constant bit_count = 24;
    uint32 constant total_header_size = 54;
    uint32 constant bi_size = 40;
    uint32 constant size_in_bytes = 32; // ((size * bit_count + 31) / 32) * 4
    uint32 constant image_size = 320; // size_in_bytes * size
    uint32 constant file_size = 374; // total_header_size + image_size

    Counters.Counter public ids;
    mapping(uint256 => bytes) public images;
    mapping(uint256 => address) public owner;

    function get() external returns (uint256) {
        ids.increment();
        uint256 id = ids.current();

        bytes memory image = generateBitmap(abi.encodePacked(msg.sender));
        _mint(msg.sender, id);
        images[id] = image;
        owner[id] = msg.sender;
        return id;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        bytes memory image = images[tokenId];
        return
            string(
                abi.encodePacked("data:image/bmp;base64,", Base64.encode(image))
            );
    }

    function generateBitmap(bytes memory seed)
        public
        view
        returns (bytes memory bitmap)
    {
        uint16[] memory random = Random.generateData(seed);
        uint8[] memory imageMap = ImageMap.generateImageMap(random);

        uint8[3] memory color0 = Random.generateColorBytes(random, 50);
        uint8[3] memory color1 = Random.generateColorBytes(random, 56);
        uint8[3] memory color2 = Random.generateColorBytes(random, 62);

        assembly {
            let data := mload(0x40)
            mstore(data, file_size)
            mstore8(add(data, add(0x20, 0x0)), 0x42) // B
            mstore8(add(data, add(0x20, 0x1)), 0x4D) // M

            mstore8(add(data, add(0x20, 0x2)), file_size)
            mstore8(add(data, add(0x20, 0xa)), total_header_size)

            mstore8(add(data, add(0x20, 0xe)), bi_size)
            mstore8(add(data, add(0x20, 0x12)), size)
            mstore8(add(data, add(0x20, 0x16)), size)

            mstore8(add(data, add(0x20, 0x1a)), 1)
            mstore8(add(data, add(0x20, 0x1c)), bit_count)
            mstore8(add(data, add(0x20, 0x22)), image_size)

            let idx := 0
            for {
                let row := size
            } gt(row, 0) {
                row := sub(row, 1)
            } {
                for {
                    let col := 0
                } lt(col, size) {
                    col := add(col, 1)
                } {
                    let pos := add(
                        0x36,
                        add(mul(sub(row, 1), size_in_bytes), mul(col, 3))
                    )

                    let color := color0
                    switch mload(add(imageMap, add(0x20, mul(idx, 0x20))))
                        case 0 {
                            color := color0
                        }
                        case 1 {
                            color := color1
                        }
                        case 2 {
                            color := color2
                        }

                    mstore8(
                        add(data, add(0x20, add(pos, 0))),
                        mload(add(color, mul(2, 0x20)))
                    )
                    mstore8(
                        add(data, add(0x20, add(pos, 1))),
                        mload(add(color, mul(1, 0x20)))
                    )
                    mstore8(
                        add(data, add(0x20, add(pos, 2))),
                        mload(add(color, mul(0, 0x20)))
                    )

                    idx := add(idx, 1)
                }
            }

            mstore(0x40, add(data, add(32, file_size)))
            bitmap := data
        }
    }
}
