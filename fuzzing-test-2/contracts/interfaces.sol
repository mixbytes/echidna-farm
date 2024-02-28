pragma solidity ^0.7.6;


interface IWETH {
    receive() external payable;
    function deposit() external payable;
    function withdraw(uint256 wad) external;
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address, uint) external returns(bool);
    function transferFrom(address, address, uint) external returns(bool);
    function decimals() external view returns (uint8);
}

interface IDAI {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address, uint) external returns(bool);
    function transferFrom(address, address, uint) external returns(bool);
    function decimals() external view returns (uint8);
}


